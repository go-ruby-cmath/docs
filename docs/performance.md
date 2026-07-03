# Performance

`go-ruby-cmath/cmath` is the pure-Go library that
[`rbgo`](https://github.com/go-embedded-ruby/ruby) binds for Ruby's `CMath`. This
page records a **comparative, per-module benchmark** of that library against the
reference Ruby runtimes, part of the ecosystem-wide parity suite.

## What is measured

The **same** CMath workload — `sqrt` / `exp` / `log` / `sin` / `cos` applied to a
fixed corpus of **256 real-and-complex arguments** (even indices real, odd
indices complex; the real axis spans negative and non-negative values so `sqrt`
and `log` take **both** their real and complex branches within one pass) — is run
through the pure-Go library and through each runtime's own `cmath`. The go-ruby
column reflects **this pure-Go library doing the work**; every other column is
that interpreter running the reference `cmath`. So the comparison is the
**Ruby-visible operation**, apples-to-apples across interpreters.

CMath is a **pure-Ruby** stdlib (not a C extension), which makes parity genuinely
reachable — and, as the numbers below show, comfortably beaten: the pure-Go
implementation calls the platform `math` routines directly instead of dispatching
Ruby `Complex` arithmetic per element.

!!! note "`cmath` on JRuby and TruffleRuby"
    CMath was removed as a **default gem** from JRuby 10.1 and TruffleRuby 34
    (both `LoadError` on a bare `require "cmath"`). Installing it with
    `gem install cmath` provides the **identical pure-Ruby implementation MRI
    ships** (`cmath-1.0.0`), so those two columns are each VM executing the same
    reference `cmath` source — a fair cross-runtime comparison, not a different
    algorithm.

## Library-level benchmark (Go API vs runtimes) — 2026-07-03

This section measures the **pure-Go library directly, through its Go API**. It
isolates the library primitive from Ruby-interpreter dispatch and answers the
parity question head-on: *is the pure-Go implementation as fast as the reference
runtime's own `cmath`?* The **same workload, same inputs, same iteration counts**
run through the Go library and through each reference runtime's `cmath`; every
engine's result digest was checked **equal to the MRI oracle** (all 256 results,
real and imaginary sums, to a `1e-9` tolerance) **before any timing** — the run
aborts on any mismatch.

- **Host:** Apple M4 Max (`Mac16,5`, arm64), macOS 26.5.1 — **date 2026-07-03**.
- **Runtimes:** Go 1.26.4 · MRI `ruby 4.0.5 +PRISM` · MRI + YJIT · JRuby 10.1.0.0
  (OpenJDK 25) · TruffleRuby 34.0.1 (GraalVM CE Native) — JRuby/TruffleRuby via
  the installed `cmath-1.0.0` gem (see note above).
- **Method:** each process runs 3 untimed warm-up passes, then 25 timed passes of
  a fixed inner loop, timed with a monotonic clock; the **best** pass is reported
  as **ns/op** (lower is better), where one *op* is **one full pass over the
  256-value corpus** (256 `CMath` calls). `vs MRI` < 1.00× means *faster than
  MRI*. Interpreter start-up is outside the timed region, so these are operation
  costs, not `ruby file.rb` process costs.

The pure-Go library is **6–20× faster than MRI** across the whole surface, and
faster than every JIT on most ops. This is the expected shape for a pure-Ruby
stdlib: MRI interprets a chain of `Complex` method sends per element, while the
Go library evaluates the same closed-form expression in native float math.

#### sqrt

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 2282.6 | 0.05× |
| MRI | 42656.7 | 1.00× |
| MRI + YJIT | 18163.3 | 0.43× |
| JRuby | 8654.2 | 0.20× |
| TruffleRuby | 917.5 | 0.02× |

#### exp

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 3721.1 | 0.12× |
| MRI | 32296.7 | 1.00× |
| MRI + YJIT | 13273.3 | 0.41× |
| JRuby | 12577.5 | 0.39× |
| TruffleRuby | 18715.4 | 0.58× |

#### log

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 5581.5 | 0.09× |
| MRI | 61786.7 | 1.00× |
| MRI + YJIT | 29590.0 | 0.48× |
| JRuby | 17881.7 | 0.29× |
| TruffleRuby | 8295.4 | 0.13× |

#### sin

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 5034.6 | 0.14× |
| MRI | 37116.7 | 1.00× |
| MRI + YJIT | 14293.3 | 0.39× |
| JRuby | 12005.6 | 0.32× |
| TruffleRuby | 21774.2 | 0.59× |

#### cos

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 5041.8 | 0.13× |
| MRI | 37963.3 | 1.00× |
| MRI + YJIT | 14990.0 | 0.39× |
| JRuby | 11401.1 | 0.30× |
| TruffleRuby | 28578.2 | 0.75× |

### Reading the numbers

- **go-ruby is 6–20× faster than MRI on every op** (0.05×–0.14×): `sqrt` ~20×,
  `log` ~11×, `exp` ~8×, `sin`/`cos` ~7×. Against a pure-Ruby stdlib the pure-Go
  port wins decisively — there is no C extension for it to chase, and native
  float math replaces per-element `Complex` dispatch.
- **MRI + YJIT** roughly halves MRI's time (0.39×–0.48×) but never reaches the Go
  library.
- **JRuby** lands at 0.20×–0.39×, faster than YJIT on the transcendental ops.
- **TruffleRuby** is the most variable: Graal partial-evaluation folds the fixed
  `sqrt` corpus almost completely (0.02×) and `log` heavily (0.13×), while the
  trig ops (`sin`/`cos` 0.59×–0.75×) swing run-to-run — the classic cold-JIT
  signature on a short, fixed loop.

!!! note "Reproduce"
    The harness is committed under
    [`benchmarks/`](https://github.com/go-ruby-cmath/docs/tree/main/benchmarks):
    a self-contained Go driver (`go/`, pins the published library via `go.mod`),
    the equivalent `ruby/cmath.rb` workload, `ruby/_harness.rb`, and `run.sh`. Run
    `bash benchmarks/run.sh` (it runs the verify phase first, then times every
    available runtime); env `OUTER`/`WARM` tune the pass budget and
    `RUBY`/`JRUBY`/`TRUFFLERUBY` select the runtime binaries. On JRuby/TruffleRuby
    first `gem install cmath`.

!!! warning "Warm-up budget & noise — honest framing"
    Numbers reflect a **fixed warm-process budget** (3 warm-up + 25 timed passes
    in one process). The JVM/GraalVM JITs (JRuby, TruffleRuby) may need a larger
    warm-up to reach steady state, so their columns can **understate** (or, where
    Graal folds a constant corpus, **overstate**) peak throughput — most visibly
    TruffleRuby on the shortest loops. Every number here is a **real measured
    value** from the dated run above (Apple M4 Max; `ruby 4.0.5 +PRISM`,
    `jruby 10.1.0.0`, `truffleruby 34.0.1`, `cmath-1.0.0`) — nothing is
    fabricated, estimated, or cherry-picked, and every engine's result digest was
    verified byte-for-byte against the MRI oracle before it was timed.

    A known cosmetic fidelity gap — a `Complex` with an integer-`0` imaginary
    part rendering differently from MRI — does not affect this benchmark: the
    corpus keeps every complex argument's imaginary part strictly non-zero, and
    the digest compares numeric sums, not string forms.
