# Custom Cursors: Creating CUR Files from Canvas

A recent product design required switching various custom, dynamic cursors at runtime. These were prepared at runtime and drawn onto a `Canvas`:

<video src="./cursor-example.mov" autoplay="true" loop="true" muted="true" width="108"></video>


In Chrome and Firefox those canvases can be used as a cursor by setting the `cursor` property in CSS to `url(canvas.toDataURL())`. The data URL is guaranteed to contain a `base64` encoded `PNG` image of the canvas.

Edge though currently only supports [`CUR` files](https://en.wikipedia.org/wiki/ICO_(file_format)). Those files wrap the cursor image, optionally at different sizes, with some metadata. Luckily for us, a newer version of the CUR file format allows embedding `PNG` file data directly.

So I wrote a small library that reads a canvas into `PNG` blob and then inserts this data into a new `Blob` that builds up the `CUR` file. We can then create an `ObjectURL` of that `CUR` file which can be used in CSS similarly to the above method.

Example:

```js
// call the `curObjectURLFromCanvas` function to retrieve an object URL pointing to a `CUR` file containing the canvas' image
const cursorObjectURL = curObjectURLFromCanvas(canvas);

// Use this URL in your inline style (or in a programatically created `StyleSheet`)
body.style.cursor = `url(${cursorObjectURL}), pointer`;
```

The library is called `cursor-utilities` and is available on [npm](https://www.npmjs.com/package/cursor-utilities), and the source is on [GitHub](https://github.com/tp/cursor-utilities).