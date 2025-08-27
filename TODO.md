1. Implement a single request manager. So that the two queries with same keys wouldn't fetch twice, but wait for the first one to finish and just load cache.

2. Maybe the resolution of the problem that iM having with caching filtered responses would be to give them some time to live. So if you change filters - you dpn't need to refetch, unless the cache has lived longer than it's time. Then we can refetch for the filters to get new data.

3. Better error handling for paginated queries.
