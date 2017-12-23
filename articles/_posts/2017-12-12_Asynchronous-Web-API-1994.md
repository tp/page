# Asynchronous Web APIs in 1994

After going down a [Hacker News](https://news.ycombinator.com/item?id=15898919) initiated rabbit hole, I crossed [Donald Knuth's 2017 Christmas Lecture](https://www.youtube.com/watch?v=BxQw4CdxLr8) and from there ended up on the [Online Encyclopedia of Integer Sequences](http://oeis.org/).

For every integer sequence you provide, it lists the known occurrences and, if available, formulae that can be used to generate them.

One interesting detail is, that every page still had a "generated in _N_ seconds" footer, where _N_ often was > 5s for my test queries. So it seems like searching 295.000 possible sequences still takes a little computing time, even on modern hardware.

But while getting an answer on modern hardware in a few seconds is acceptable, let's image how much longer this might've taken a few year back.

In order to offer advanced searches and explain sequences a new service was established in 1994: ["Superseeker"](http://oeis.org/ol.html). As this services does some "serious computing", we can take a guess at how much longer it must've taken to complete a query.

So in order to offer this at that time (where homes still had per-minute dial-up), the search API was implemented  on top of plain e-mail.

That way the server could take as long as it needed to generate a response, and the sender would be notified as soon as possible once the calculation was done. What a beautifully simple approach.

----

Software based on the original bunch of shell scripts from back then is still in use and it's source code is available [here](http://oeis.org/ol_source.txt).



