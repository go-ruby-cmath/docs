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

!!! note "Honest framing"
    No measured figures are published here yet — only the methodology above.
    When the per-module run lands, the table will carry **real measured numbers**
    from a dated run, with JRuby/TruffleRuby timed cold (single-shot) exactly as
    `rbgo` and MRI are, so the comparison stays apples-to-apples. Nothing is
    cherry-picked, and nothing is quoted until it has been measured on this
    module.
