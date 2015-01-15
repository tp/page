---
title: Making HTTP requests beyond the 32MB urlfetch limit on Google App Engine
layout: default
---

# {{ page.title }}

Since Google App Engine's `urlfetch` service [imposes a 32MB response size limit](https://cloud.google.com/appengine/docs/go/urlfetch/#Go_Quotas_and_limits) on each request, one has to roll their own [http.Client](http://golang.org/pkg/net/http/#Client) implementation using `appengine/socket` to make requests exceeding that limit.

Sadly the `appengine/socket` implementation is [not working with HTTP calls inside the local development server](https://code.google.com/p/googleappengine/issues/detail?id=11076), such that one can not use the same solution and code in development and production.

The two issues made me create the [`fetchall` package](http://godoc.org/timm.io/fetchall), a simple drop-in replacement for `urlfetch` that gives you a `http.Client` implementation that handles arbitrarily large HTTP requests (within the time limits of Google App Engine).

When running in the development server, the implementation will simply use Go's `net` package instead of `appengine/socket` in order for request to work locally as well as in the cloud.

To use this package simply replace `urlfetch.Client` with `fetchall.Client` in your Go code.

GitHub: [github.com/tp/fetchall](https://github.com/tp/fetchall)  
GoDoc: [godoc.org/timm.io/fetchall](http://godoc.org/timm.io/fetchall)