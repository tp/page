---
title: Fetching Potentially Compressed Webpages That Might Not be UTF-8 Encoded in Rust
layout: default
---

> **TL;DR** This write-up explains how I build my first Rust crate to fetch compressed, non-UTF-8 encoded webpages.
If you want to get straight to the code grab the [final `fetch` crate on crates.io](https://crates.io/crates/fetch) or [view the source on Github](https://github.com/tp/fetch-rs).

For a side-project I needed to download some arbitrary webpages (HTML or plain text only). In absence of a targeted shipping date, I decided to use this opportunity to write this piece of software in [Rust](https://www.rust-lang.org/) which I have interestedly observed for a long time but never actually used.

## Preparation

Since there is no http client in the [Rust standard library](https://doc.rust-lang.org/std/) I picked the currently most popular http library on [crates.io](https://crates.io/search?q=http&sort=downloads): [hyper](https://github.com/hyperium/hyper).

The [basic client example](http://hyper.rs/hyper/v0.9.10/hyper/client/index.html#get) looked fine initially but quickly turned out to be insufficient when testing with a variety of sites. 
Many sites send compressed or non-UTF-8 encoded data, and while the former could often be solved by setting the `Accept-Encoding` header to `identity`, the latter required some more changes to the program since strings are always [UTF-8 encoded in Rust](https://doc.rust-lang.org/std/string/struct.String.html#utf-8) and thus needed to be converted.

So I expanded my list of dependencies to the following set of crates:

* [hyper](https://github.com/hyperium/hyper): [http client](http://hyper.rs/hyper/v0.9.10/hyper/client/index.html) to retrieve the data from the server
* [flate2](https://github.com/alexcrichton/flate2-rs): compression library that is used to decode [gzip](https://en.wikipedia.org/wiki/Gzip) and [DEFLATE](https://en.wikipedia.org/wiki/DEFLATE) compressed responses
* [encoding](https://github.com/lifthrasiir/rust-encoding): character set conversion from various encodings to Rust strings

## Implementation

First let's look at how easily the current implementation make it to fetch a pages body as `String`:

```rust
let body = fetch::fetch_page("https://www.rust-lang.org/en-US/");
```

> The final project used for the prototype and this blog post is available on Github at [tp/fetch-rs](https://github.com/tp/fetch-rs). It has also been publish as the [`fetch` crate on crates.io](http://crates.io/crates/fetch).

Like alluded to above, I started out with a simple `hyper` client that worked fine for the first few manual fetches. I could just read the response into a string using:

```rust
let mut body_buffer = String::new();

response.read_to_string(&mut body_buffer);
```

But this would fail when the page was not encoded in UTF-8 or would just return garbled output for compressed content.

So I went looking for an encoding and a decompression library, which let me to `encoding` and `flate2`.

Now things became a little more involved since I had to explore the 2 new crates, which had to be done differently from how I would normally approach this, since full autocompletion for crates [is not yet available](https://github.com/phildawes/racer/issues/551). But thanks to the pervasive use of [`rustdoc`](https://doc.rust-lang.org/book/documentation.html#about-rustdoc) there is a good amount of documentation on every crate that I encountered.

So after a while of reading the API documentations, I was able to unzip the response body

```rust
let mut unzipped_body_buffer = Vec::new();
GzDecoder::new(body_buffer.as_slice());
d.read_to_end(&mut unzipped_body_buffer);
```

and also convert the given charset to UTF-8:

```rust
let decoder = encoding_from_whatwg_label(charset).unwrap();
return decoder.decode(&unzipped_body_buffer, DecoderTrap::Strict)
```

_[Please note that the examples above are abbreviated excerpts from the actual source code and do not contain proper error handling. Please look at the [source](https://github.com/tp/fetch-rs/blob/master/src/lib.rs) to see how errors are currently handled.]_

Once my spot checks succeeded, I wanted to try the Rust testing facilities to ship some tests with the library. As it turns out, testing your code is super easy: Just annotate test functions in your library with `#[test]` and run `cargo test`.

Currently I just check whether the fetch returns a [success value](https://doc.rust-lang.org/std/result/enum.Result.html), but as a next step I want to setup a test server and compare the whole response body to a reference file.

```rust
#[test]
fn fetch_deflate_compressed_page() {
    fetch_page("http://httpbin.org/deflate").expect("Fetch to succeed");
}
```


After all tests passed[^1] I was satisfied with the initial scope of library and went on to publish it to crates.io.

This turned out to be a little bit trickier than it probably should have been, due to me initially naming the crate “http-fetch”.

When integration testing the crate with another project I soon found out that while your crate name on crates.io can contain a hyphen, you have to import it with a [different](http://stackoverflow.com/questions/31846789/crate-name-with-hyphens-not-being-recognized) [name](https://m.reddit.com/r/rust/comments/4rlom7/what_characters_are_allowed_in_a_crate_name/d52bdyp) when using it in Rust code. Not wanting to explain this (confusing) behavior in the README I decided to rename the crate (which I had already published). Since it was not possible to rename from “http-fetch” to “http_fetch” for some reason (cargo would not allow this), I created a new crate named “[fetch](crates.io/crates/fetch)”.


## Retrospection

Though this project is small and in a functional state right now, there are already a number of points that I need to dig into deeper before writing more complex programs in Rust:

**Error handling**: In order to return errors from `fetch` using the [Result](https://doc.rust-lang.org/std/result/enum.Result.html) type which requires a common interface for all possible errors I am currently transforming all errors and replace them with a string containing a short description of where the error occurred. Sadly this looses the original error, which the call side might want to evaluate to help with debugging etc.

**[Borrowing](https://doc.rust-lang.org/book/references-and-borrowing.html#borrowing) and Ownership**: When reading into the buffer a second time I would get [error E0506](https://doc.rust-lang.org/error-index.html#E0506) reported by the compiler. While I don't yet fully understand the reason for this, the suggested solution of just scoping offending code in its on `{ }` block works.

A lack of understanding [lifetimes](https://doc.rust-lang.org/book/lifetimes.html) has also so far prevented me from breaking the code up into smaller functions, which would require some special annotations (I assume).

All in all I was highly rewarded for this experiment by being exposed to new concepts and different approaches to API design and programming altogether. Furthermore I was positively surprised how quick I could pursue and find my way around the crates given the lack of full code completion. Thanks to great documentation being available for all crates used, this was not as big of a slowdown as I would have expected initially.

Now I am looking forward to writing more code in Rust and get a better understanding of and write future-proof solutions for the issues mentioned above. 

[^1]: Which was did not succeed immediately, since I had an error with DEFLATE compressed responses. Turns out you have to run them through the [`ZlibDecoder`](http://alexcrichton.com/flate2-rs/flate2/read/struct.ZlibDecoder.html) instead of the [`DeflateDecoder`](http://alexcrichton.com/flate2-rs/flate2/read/struct.DeflateDecoder.html) which I assumed at first (given the name). So, lesson learned, always test your code 🤗