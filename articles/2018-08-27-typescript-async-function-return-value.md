# TypeScript: `ReturnType` for `async` `function`s

[Playground](https://www.typescriptlang.org/play/#src=%0D%0Aasync%20function%20three()%3A%20Promise%3C3%3E%20%7B%0D%0A%20%20%20%20return%203%0D%0A%7D%0D%0A%0D%0Atype%20X%20%3D%20ReturnType%3Ctypeof%20three%3E%0D%0Atype%20PromiseValue%3CE%3E%20%3D%20E%20extends%20Promise%3Cinfer%20T%3E%20%3F%20T%20%3A%20never%3B%0D%0A%0D%0Atype%20dreiQM%20%3D%20PromiseValue%3CReturnType%3Ctypeof%20three%3E%3E%0D%0Aconst%20m%3A%20dreiQM%20%3D%203)


https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-8.html

https://github.com/bkase/swift-di-explorations