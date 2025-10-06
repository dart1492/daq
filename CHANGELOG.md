## 0.0.2

Includes useMutation, useQuery and usePaginatedQuery. Plus some utility widgets, hooks, classes to make it work.

## 0.0.3

I've decided to get rid of the `usePaginatedQuery` for now, and replace it with `useInfiniteQuery()`. These two are almost identical in their usage, but the infinite one is better suited to the "infinite- scrolled-list-on-mobile" kind of use-case.

I have also added:

- Request deduplication (requests for the same key are getting queued to avoid duplicate execution and cache updates).

- Time to live. Now configurable for `useQuery()` and `useInfiniteQuery()` (can be set for each hook usage individually or in the DAQProvider configuration globally). Works in a reactive way (with the timer going under the hood that will refetch the query if it's time has come). This feature is only implemented in it's basic form and needs some more work on edge-cases (think about internet connectivity, bringing the app from background state - that kind of stuff).

- Helper methods to work with cache mutations (still need more work).
