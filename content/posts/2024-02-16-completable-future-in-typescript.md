
---
title:  "Completable Future in TypeScript"
description: I promise that you will get that value in the Future, you just need to await for it!
date:   2024-02-16
tags: [tech, english]
---

For an application that I'm currently developing, there are two components that are called from a central entrypoint function.
It has now come to the point where I need to share data _after it was properly initalized_ in the one component, to the other component.
The other component can start off its journey, but will need to wait at some point until the data is available.

Java has a function for that, the `CompletableFuture` [[Baeldung](https://www.baeldung.com/java-completablefuture)], but there's no simple equivalent in JavaScript.

Of course, I want to avoid the need for top-level/global properties since they're both ugly and unsafe to use, especially if the resolving component has async code around.

The _sender_ should be able to call a function `resolve: (value: T) => void;`, and the _receiver_ should wait with `const value: T = await future`, so the code for the type looks like this:

```typescript
type Future<T> = {
    resolve: (value: T) => void;
    future: Promise<T>;
};
```
An option to implement that feature is to piggyback on the Promise API: An initalizer for the Future will then make use of the `await` functionality of Promises, extract the resolve function in the executor (that's the callback in the Promise constructur) and return both the promise and the resolve callback:

```typescript
export const createFuture = <T>(): Future<T> => {
    var resolve: (value: T) => void;

    const future = new Promise<T>((r) => {
        resolve = r;
    });

    return {
        // @ts-ignore
        resolve, 
        future
    };
};
```

There is this stinky `@ts-ignore` in the return statement, since the resolver is only assigned in the Promise executor.
While the executor is called synchronously [[see MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/Promise#:~:text=The%20executor%20is%20called%20synchronously%20(as%20soon%20as%20the%20Promise%20is%20constructed)%20with%20the%20resolveFunc%20and%20rejectFunc%20functions%20as%20arguments.)], this is somehow not respected by the type system, which then complaints that `resolve` may be uninitialized.

I hope that helps whoever needs to share state between two components.