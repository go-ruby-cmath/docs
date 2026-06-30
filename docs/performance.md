# Performance

`go-ruby-cmath/cmath` is the pure-Go library that
[`rbgo`](https://github.com/go-embedded-ruby/ruby) binds for Ruby's `CMath`. This
page records the **methodology** of the ecosystem-wide per-module parity
benchmark; it does not quote numbers that have not been measured on this module.

## What is measured

The **same** Ruby script — a `CMath` workload exercising `sqrt` / `exp` / `log`
and the trig / hyperbolic families over a mixed real / negative / complex corpus
— is run under every runtime. `rbgo`'s number reflects **this pure-Go library
doing the work**; every other column is that interpreter's own `cmath` stdlib.
So the comparison is the **Ruby-visible operation**, apples-to-apples across
interpreters. The script prints a deterministic checksum and its output is checked
**byte-identical to MRI** before timing.

## Method

- **Host:** a single fixed machine; **best-of-N wall time** (best, not mean, to
  suppress scheduler noise); single-shot processes, no warm-up beyond the
  script's own loop.
- **Runtimes:** `ruby` (MRI, the oracle) and `ruby --yjit`; `jruby`;
  `truffleruby` — each running its own `cmath`, against `rbgo` running this
  library.
- The benchmark script and harness live in rbgo's repo under
  [`bench/modules/`](https://github.com/go-embedded-ruby/ruby/tree/main/bench/modules).
  Reproduce with the per-module runner there.

## Result (best of 5, ms)

| Runtime | time | vs MRI |
| --- | ---: | ---: |
| **rbgo** (go-ruby-cmath) | 40 | 0.67× |
| MRI (ruby 4.0.5) | 60 | 1.00× |
| MRI + YJIT | 60 | 1.00× |
| JRuby 10.1.0.0 | n/a* | — |
| TruffleRuby 34.0.1 | n/a* | — |

\* *`cmath` is not bundled in JRuby 10.1 or TruffleRuby 34 (both `LoadError` on `require` — it was removed as a default gem in those distributions), so no JRuby/TruffleRuby number could be measured. The row runs on MRI, MRI+YJIT and rbgo.*

rbgo runs on **go-ruby-cmath** and is **faster than MRI** here (0.67x) on this complex-transcendental sweep. `cmath` is **not bundled** in JRuby 10.1 or TruffleRuby 34 (both `LoadError` on `require` — it was removed as a default gem), so those two columns have no number.

!!! note "Honest framing"
    JRuby and TruffleRuby are timed **cold, single-shot**, so they carry JVM /
    Graal startup on every run — read them as one-shot `ruby file.rb` costs, the
    same way `rbgo` and MRI are measured, not as steady-state JIT numbers. Rows
    that complete in well under ~200 ms carry the most relative noise; treat
    their ratios as order-of-magnitude. These are **real measured numbers** from
    the 2026-06-30 run (Apple M-series; `ruby 4.0.5 +PRISM`, `jruby 10.1.0.0`,
    `truffleruby 34.0.1`) — nothing is fabricated or cherry-picked.
