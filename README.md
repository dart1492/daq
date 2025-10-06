## DAQ or darts_async_query

Heavily inspired by [TanStack Query](https://tanstack.com/query) and [RTKQ](https://redux-toolkit.js.org/rtk-query/overview), as well as their closest Flutter analog - [FQuery](https://github.com/41y08h/fquery).

DAQ is an asynchronous state management package for Flutter applications, that tries to mimic the well-beloved approach of relevant React packages working in Flutter environment.

### Prerequisites

To work, DAQ requires you to use [Flutter Hooks](https://pub.dev/packages/flutter_hooks/install). It could have written it in two different ways, but for now Im sticking to hooks, because I love the approach.

### Quick usage guide

To start "querying" and "mutating" you would first need to provide the DAQCache instance through context. For that just wrap the app in DAQProvider and edit the configuration (optional) - and from there on you can access the cache instance by using thr `useDAQ()` method.

```
...
...

    DAQProvider(
        daqCache: DAQCache(config: DAQConfig()),
        child: YourApp(),
    ),

...
...
```

After that you can access the `useMutation()`, `useQuery()` and `useInfiniteQuery()` in every widget, that extends some kind of a Hook widget (`MyWidget extends HookWidget`, for example).

More documentation on these three coming later, but for all users familiar with inspirations for this package it shouldn't be a problem to figure out how they work.

### Roadmap

The package is in an early development stage, and I haven't yet implemented a lot of auxiliary stuff that would be great to have.

If you are willing to share any comments/provide insight or guidance - I'
d be very happy to listen to you!
