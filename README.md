# FSCQ
FSCQ is a file system written and verified in the Coq proof assistant.

# IO Concurrency

## Concurrent programs

State includes memory (hlist) - high-level variables of arbitrary types.

Also track ghost state for specifications (another hlist).

Concurrent programming language `cprog` has associated protocol (delta) with invariant (tying disk/memory/ghost state together) and relation (`guar`, specifying what transitions are allowed). (Note: for exposition we write `cprog` here but the code just uses `prog` from `CoopConcur.v`.)

Threads normally have exclusive access to the CPU but can Yield; between Yield points each thread guarantees the global relation `guar tid`, whereas upon completion Yield guarantees that other threads' `guar` steps occurred. This is derived from `guar` and provided in a definition `rely`.

In addition to the relational specification, threads guarantee that the invariant holds at Yield points. This allows a clean specification of much of the global protocol for one thing, but is also used to connect disk and memory to ghost state so that the global relation can be defined purely over ghost state - if a variable in memory must be mentioned, it can be mirrored in the ghost state and the mirroring enforced by the invariant.

In practice `prog` needs several more instructions for these things -- reading/writing to memory variables (`Get` and `Assgn`), updating ghost state, and `Yield`.

Finally, rather than async disk writes (which complicate crashes but don't affect normal execution) we need async disk reads (which complicate normal execution but are irrelevant to crashes). These are modeled by a pair of operations `StartRead` and `FinishRead`.

`StartRead` adds a reader to a disk address, `FinishRead` removes the reader (idea: block until read finishes) and returns the current value. Both fail if current rdr state is unexpected (ie, cannot issue two reads at once, and `FinishRead` requires a matching `StartRead`).

(More complicated) alternatives: track list of readers (no need, complicated state), allow read/write races and track what value should be returned for each read (why support races?). Somewhat subtly, the latter relaxation allows us to get away with `FinishRead` returning the current value, rather than having reads complete non-deterministically, storing a value that is later returned -- the lack of concurrent writes means across a read the value will not change in a provable program.

in practice do `StartRead; Yield; FinishRead` and augment `Yield` with an address for Haskell scheduler to know when this thread should be woken up, so `FinishRead` doesn't block

note that `Read a := StartRead a; v <- FinishRead a; Ret v` (expanded along monad right identity for clarity)

## IO concurrency cache

Provides one layer of regular buffer caching (same type as underlying disk).

Includes another layer for write buffer to support discarding a set of writes (when a system call fails, we don't want other threads to observe partial progress)

The cache exposes four operations:

1. `cache_read a : prog (option valu)`

  read from the cache - if misses in the cache, schedule a read; if there's already a scheduled read, retrieve the result, fill the cache, and return it
2. `cache_write a v : prog bool`

  write to the cache - if there's a pending read, fail and return false
3. `cache_commit : prog unit`

  move buffered writes in the WriteBuffer into the main cache.
4. `cache_abort : prog unit`

  cancel all buffered writes (restoring to old values) in the WriteBuffer

The state of the cache two disks, a committed disk (we will call this vdisk0) and a current partially structured disk (vdisk). If the state is (vd0, vd), abort goes to (vd0, vd0) whereas commit goes to (vd, vd).

In reality the code is currently messy - vdisk0 is actually hide_readers (get vDisk0 s). This can and should be fixed.

Note that the cache code never yields - it is the caller's job to trap read/write failures, abort, and then yield.

## Copy example

The file [ConcurrentCopy.v](src/ConcurrentCopy.v) demonstrates an example "application" written on top of the cache. The idea is for each thread `tid` to copy a block from address 0 to `tid + 1`. The global protocol states that only `tid` may modify address `tid + 1` - note that this makes block 0 read-only. The spec for `copy` promises that the program actually does the expected copying. Of course the cache operations required could fail, in which case `copy` Yields and does nothing.

In addition, here we add an invariant on the cache that the cache is always committed. Recall that invariants must hold between Yield points. This means each cache transaction consists of writes from a single thread, which makes reasoning about aborts simpler. `copy` is so simple that its abort is always degenerate, since it never has partially written state (once the write succeeds, it returns).

The condition that the cache is committed between Yield points seems sensible to move into the cache itself, since we never plan on having two threads cooperate on some writes and then coordinate on a single commit. Each cache transaction will correspond to a system call, performed by one thread.

## Concurrent Simulation

Concurrent cache can simulate sequential programs.

Reads can fail (cache miss).

Writes can fail (due to a concurrent read - technically safe to succeed the write and fail the read + not fill, but this is complicated).

Simple compiler translates sequential programs into cache programs, with type `forall A, prog A -> cprog (option A)`. When the `cprog` returns `None`, a read or write failed and the entire program has been conceptually replaced with a Yield (except for some internal cache operations).

Correctness theorem: converted program behaves the same as original if failure doesn't occur, and on failure does nothing other than a rely step. The full correctness theorem will also translate specs; whereas a sequential spec is applied to the disk, the concurrent spec is applied to the ghost virtual disk exposed by the cache.

For the purposes of proving something about a complete concurrent program, the cache is parametrized over a global protocol. The global protocol will be instantiated with an invariant connecting the (cache virtual) disk to a directory tree (another ghost variable). As a first proof of concept, the global relation will specify that each directory is owned by a particular thread and other threads cannot modify it, which will let us run system calls under the appropriate directories, including with safe retries.

Ultimately also want generic retry loop: need to know that rely steps preserve the operation's precondition, then can prove (tricky, retry loop is a cofixpoint) that the retry-looped program has exactly the same pre-post spec (unconditional, taking advantage of fact that we are proving only partial correctness).