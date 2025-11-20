2. Work with network state (for example refetch when the network is switched from offline to online)

3. Add garbage collection. For cache that has no uses to be collected after some amount of time passes (configurable).

4. Add a silent retry on failed queries (configurable).

5. Add invalidation and mutation "emitEvent" parameters to enable/disable reactivity on them

6. Add global handlers (like global onSuccess, onError, etc.)
