# TypeScript: `ReturnType` for `async` `function`s

Since the introduction of the `ReturnType` in [TypeScript 2.8](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-8.html), we can build up types based on the results of functions, without mentioning the types explicitly:

```ts
function createContext<T extends () => any>(configProvider: T): { config: ReturnType<T> } {
    return {
        config: configProvider(),
    }
}

function apiConfig() {
    return {
        endpoint: 'https://www.example.com'
    }
}

/**
 * context has type `{ config: { endpoint: string; }; }`
 */
const context =  createContext(apiConfig);
```
[Playground](https://www.typescriptlang.org/play/#src=%0D%0A%0D%0Afunction%20createContext%3CT%20extends%20()%20%3D%3E%20any%3E(configProvider%3A%20T)%3A%20%7B%20config%3A%20ReturnType%3CT%3E%20%7D%20%7B%0D%0A%20%20%20%20return%20%7B%0D%0A%20%20%20%20%20%20%20%20config%3A%20configProvider()%2C%0D%0A%20%20%20%20%7D%0D%0A%7D%0D%0A%0D%0Afunction%20apiConfig()%20%7B%0D%0A%20%20%20%20return%20%7B%0D%0A%20%20%20%20%20%20%20%20endpoint%3A%20'https%3A%2F%2Fwww.example.com'%0D%0A%20%20%20%20%7D%0D%0A%7D%0D%0A%0D%0A%2F**%0D%0A%20*%20context%20has%20type%20%60%7B%20config%3A%20%7B%20endpoint%3A%20string%3B%20%7D%3B%20%7D%60%0D%0A%20*%2F%0D%0Aconst%20context%20%3D%20%20createContext(apiConfig))

Since `async` functions are becoming more prevalent in the code I work with, I have been wondering whether a similar helper can be employed to get the type of a successfully resolved `Promise`.

As a first building block I wrote a type to extract the `Promise`'s resolved type:

```ts
type PromiseResolvedType<T> = T extends Promise<infer R> ? R : never;

// Type is currently Promise<number>
const promise = Promise.resolve(3);

// value has type `number`, will stay in sync with type of `promise` variable
let comparisionValue: PromiseResolvedType<typeof promise> = 5;

promise.then(value => console.log(`Value equal to comparison?`, value === comparisionValue));
```
[Playground](https://www.typescriptlang.org/play/#src=type%20PromiseResolvedType%3CT%3E%20%3D%20T%20extends%20Promise%3Cinfer%20R%3E%20%3F%20R%20%3A%20never%3B%0D%0A%0D%0A%2F%2F%20Type%20is%20currently%20Promise%3Cnumber%3E%0D%0Aconst%20promise%20%3D%20Promise.resolve(3)%3B%0D%0A%0D%0A%2F%2F%20value%20has%20type%20%60number%60%2C%20will%20stay%20in%20sync%20with%20%60promise%60%20variable%0D%0Alet%20comparisionValue%3A%20PromiseResolvedType%3Ctypeof%20promise%3E%20%3D%205%3B%0D%0A%0D%0Apromise.then(value%20%3D%3E%20console.log(%60Value%20equal%20to%20comparison%3F%60%2C%20value%20%3D%3D%3D%20comparisionValue))%3B)

That works nicely to limit our comparision value to the same type as the `Promise` instance might eventually resolve to. That way we can ensure consistency. If the types were not matching, the comparison will definitely fail, so we get faster feedback by moving that first check to the compile time of the program.

The final step is now to return the `ReturnType` with the `PromiseResolvedType` to access the success value of a Promise returned by a function:

```ts
type PromiseResolvedType<T> = T extends Promise<infer R> ? R : never;
type ReturnedPromiseResolvedType<T> = PromiseResolvedType<ReturnType<T>>
// or flattened: type ReturnedPromiseResolvedType<T> = T extends (...args: any[]) => Promise<infer R> ? R : never;

async function random(): Promise<number> {
  return Math.random();
}

type RandomFuncResolvedType = ReturnedPromiseResolvedType<typeof random>; // number
```
[Playground](https://www.typescriptlang.org/play/#src=type%20PromiseResolvedType%3CT%3E%20%3D%20T%20extends%20Promise%3Cinfer%20R%3E%20%3F%20R%20%3A%20never%3B%0D%0Atype%20ReturnedPromiseResolvedType%3CT%3E%20%3D%20PromiseResolvedType%3CReturnType%3CT%3E%3E%0D%0A%2F%2F%20or%20flattened%3A%20type%20ReturnedPromiseResolvedType%3CT%3E%20%3D%20T%20extends%20(...args%3A%20any%5B%5D)%20%3D%3E%20Promise%3Cinfer%20R%3E%20%3F%20R%20%3A%20never%3B%0D%0A%0D%0Aasync%20function%20random()%3A%20Promise%3Cnumber%3E%20%7B%0D%0A%20%20return%20Math.random()%3B%0D%0A%7D%0D%0A%0D%0Atype%20RandomFuncResolvedType%20%3D%20ReturnedPromiseResolvedType%3Ctypeof%20random%3E%3B%20%2F%2F%20number)

