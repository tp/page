# `usePromise`: A React hook for async data loading with server-side rendering (SSR) support

<div class="note"><b>Out now:</b> This post explores the background behind a new library, usePromise, that is now <a href="https://www.npmjs.com/package/@timm/use-promise">available on NPM</a>. The source code and examples are available on <a href="https://github.com/tp/use-promise">GitHub at tp/use-promise</a>.</div>

React hooks can help build components made up of re-usable smaller helpers while still staying readable and clear even when a bunch of features are combined. This is a nice contrast to the previous lifecycle methods across in which multiple "extensions" wheren't always clearly visible - might it be because they only appeared in some methods, or because they appeared in a different order in each one and hence weren't as easily scannable.

So when looking at a component design that would allow for 100% custom components to be injected into an app skeleton, fetching data via hooks seemed like a great solution. In contrast to render props and similar approaches, it doesn't limit the consumer to what is provided by the outside helper in one pattern, and then force one to use a possibly different approach to load further data. (Or use nested render props components, which IMHO don't read that well and still require manual passing of the props.)

So I was a little surprised to find out that as of now (React 16.8) one couldn't easily compose a new hook for async data loading (with SSR support) for 2 reasons:
1. State managed using the `setState` hook couldn't be read out and be transferred to the client
2. Loading data asynchronously, and hence calling `setState` after the initial render on the server, doesn't work with the current default model, which only renders once.

Point #2 seems like a reasonable general limitation, because when you trigger the data loading in the component to be rendered, one for sure needs to attempt to render that component again after the data has been loaded. Rendering `n + 1` times (_n_ for each data loading operation and then once for the final render to find out that there is nothing new to fetch) is an overhead not to take lightly, but [luckily React is working on a remedy to make this more lightweight with `Suspense` in the future](https://reactjs.org/blog/2019/08/08/react-v16.9.0.html#an-update-to-the-roadmap).

So while waiting on React to support #2 by default and at the same time adding a solution for #1 for the specific context of data-loading which does not require learning and setting up any state-management solution, I looked into building a small hook that would accomplish this.

The challenge, as mentioned before, is that any component in the tree could trigger a data-fetching operation, and then rendering would need to halt until that `Promise` is resolved. In lieu of `Suspense` the best I could come up with was to use the approach of rendering the whole tree again (something I also observed Apollo do) after each individual data loading operation has completed. Taking another page from the current `Suspense` playbook, whenever a component wants to load data via this new hook, it `throw`s that `Promise`, which the library then `await`s before attempting to render again. Once a render completed without any new `Promise` being scheduled (`throw`n), that rendering is taken as the final result and sent to the client.

In standard hooks fashion the library builds up an array holding the data of the single ongoing and potentially many completed `Promise`s. This data is then distributed on each rendering attempt to the hooks in order. Since this is only needed on the server (in an unchanging render tree) and then once for rehydration on the client, there is no issue with using this one global array (scoped to the current request) for the whole page (instead of a per component array which React itself uses).

The final data of all Promises is then serialized into the HTML send to the client, where it's used for the initial rehydration, after which it switches to rely on React's `setState` for managing further mutations.

In then end the usage looks like this:

```ts
function WhatToWear() {
    const {loading, error, data} = usePromise(() => weatherApi.getCurrentWeatherAsync());

    if (loading) {
        return <div>Loading…</div>
    }

    if (error) {
        return <div>An error occured…</div>
    }
    
    return <div>Recommended outfit: {weather.temp > 19 ? '👚' : '🧥'}</div>;    
}
```

The plan is now to take the `usePromise` helper and build up hooks for the specific domain, so the consumer wouldn't have to deal with providing the `Promise` creating function herself.

In the end the resulting API is really small, just one line to pull in a some fully typed data and have the library taking care of data loading on the server. Additionally the consumer now has to take care of rendering the `loading` and `error` cases, but that would be something they will have to deal with in any case, unless they're fine with rendering some default message, which could easily be achieved with a helper component.

Overall I am quite happy how this turned out on the usage side, even though the implementation has some rough edges and overhead at the moment. Possibly the overhead can be reduced in the future with `Suspense` – if this library will not be made obsolete outright by it. In either case, the transition to some future React version should be smooth, very likely allowing us to keep the same outside API.

For now this is exactly what was needed and building up on so much great technology and inspiration I was happy to see how it could be achieved in a short amount of time.

## Thoughts on API design

Initially the library followed the `useState` approach and returned an array of type `[boolean, T, unknown]`, which could be used for example as `[completed, weather, error]` (in the example case of fetching the current weather). The interesting bit here is how the array model doesn't even suggest default names, and the user is forced to pick some for his use-case. But just having the types might be confusing in 2 cases: When not using / seeing the types immediately in the editor, or when the return type is `boolean` or anything unspecific like the `unkown` error type. In those cases it might not be obvious at which index the result is stored, especially if the library is not very familiar to the user (unlike `setState` which one probably interacts with daily in a hooks-using codebase).


The array approach was then debated, and since the primary use case was data loading, the API was changed to match Apollo's `useQuery` ([the actual types are more specific](https://github.com/tp/use-promise/blob/b0dab8d5dfce28d45a6667a180e15f0fa92c1d7b/src/index.ts#L4) than the example below): 


```ts
{
    loading: boolean;
    data: T;
    error: Error;
}
```

As you can see, it's now an object which provides explicit names for each field. `completed` flipped to `loading`, which makes writing early returns much nicer. `error` is now limited to `Error`, but that might just be a temporary solution. What I wanted to achieve there was that `error` could be checked with a simple `if`, and if it was falsy the `Promise` would have resolved successfully and `data` would contain the result.

Remapping the names to something specific is still easily possibly.

One further consideration was how use the hook multiple times in a row. Then having multiple `loading` and `error` states might get very cumbersome, especially since you musn't return early for any `Promise` rejection.

In the end the current design and documentation hopefully leads people to write a single helper function loading all relevant data for a component. This is a lot more efficient with the current implmentation detailed above, as well as making the component clearer as it has less states to think about.

If you have any feedback on the API design, for example feeling it's now to focused on data loading, or any other suggestions [feel free to open a ticket with your feedback](https://github.com/tp/use-promise/issues).

## Closing Thoughts

One thought that always pops up in my head when working on components which trigger or manage their own data loading – especially whenn this done across multiple layers of components – is whether it's desirable and should be done that way at all. 

I think it's always worth to imagine what the alternative design of having a storage & side-effect solution outside of the component tree would look like and what benefits one might gain from it. Compared to the above example, one clear benefit would be that one could do the data loading first, and then be done after a single render. On the other hand that forces one to combine all data-fetching logic into a single step on this "other side" – which might or might not be a good thing.

In the end this boils down to picking what's right for the problem at hand. In the above case the goal was to make it easy to insert 1 or 2 data loading hooks across a page, and for that it seems far more approachable than learning any specific store system and hooking into it.

<div class="alert">👨🏼‍💻If you strive to make life developing web applications easier and enjoy exploring beyond the known solutions <a href="https://corporate.aboutyou.de/de/jobs/senior-frontend-developer">this might job might fancy your interest</a>.</div>