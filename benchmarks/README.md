<!-- SPDX-License-Identifier: BSD-3-Clause -->
# `go-ruby-cmath` library-level benchmark harness

Reproducible, cross-runtime benchmark of the **pure-Go `go-ruby-cmath/cmath`
library** against the reference Ruby runtimes (MRI, MRI + YJIT, JRuby,
TruffleRuby). It measures the **library primitive** through its Go API, isolated
from the rbgo interpreter, so the numbers answer: *is the pure-Go implementation
as fast as the reference runtime's own `cmath`?*

## Layout

- `go/`            — self-contained Go driver; `go.mod` pins the published library
  by pseudo-version (not a `replace`). The built `go/bench` binary is git-ignored.
- `ruby/cmath.rb`  — the equivalent workload; `ruby/_harness.rb` is the shared
  timer.
- `run.sh`         — verifies every engine against the MRI oracle, then runs each
  available runtime and prints one Markdown table per sub-benchmark (ns/op + ratio
  vs MRI).

## Run

```sh
bash benchmarks/run.sh
```

Environment knobs: `OUTER` (timed passes, default 25), `WARM` (untimed warm-up
passes, default 3), `TOL` (verify tolerance, default `1e-9`), and
`RUBY`/`JRUBY`/`TRUFFLERUBY` to select runtime binaries.

`cmath` was removed as a default gem from JRuby 10.1 and TruffleRuby 34; run
`gem install cmath` on each before benchmarking them (it installs the same
pure-Ruby `cmath-1.0.0` MRI ships). A runtime that is absent, or still missing
`cmath`, is skipped with a note rather than failing the run.

## Method

Each process runs `WARM` untimed passes (to let the JVM/GraalVM JITs warm up),
then `OUTER` timed passes of a fixed inner loop, timed with a monotonic clock;
the **best** pass is reported as **ns/op** — one *op* being a full pass over the
256-value real-and-complex corpus. Interpreter start-up is outside the timed
region. The Go driver and the Ruby script build **identical inputs** (the same
deterministic corpus, using exact binary fractions so the doubles are
bit-identical), and a **verify phase** confirms every engine's result digest
equals MRI's (all 256 results' real and imaginary sums, within `TOL`) before any
timing — a mismatch aborts the run. Results are published, dated, in
`../docs/performance.md`.
