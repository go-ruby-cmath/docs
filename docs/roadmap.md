# Roadmap

`go-ruby-cmath/cmath` is grown **test-first**, each capability differential-tested
against MRI rather than built in isolation. Ruby's `CMath` standard library — the
deterministic, interpreter-independent slice — is **complete**.

| Stage | What | Status |
| --- | --- | --- |
| The `Number` value model | A real-or-complex value, the Go analogue of Ruby's `Float`-or-`Complex`; `Real(x)` and `Complex(re, im)` build arguments, and `Complex(re, 0)` stays complex (as `Complex(1, 0).real?` is `false`). | **Done** |
| Real-vs-complex branch | Each function returns a real result on the real branch (`Sqrt(Real(4))` is `2.0`) and a complex result otherwise (`Sqrt(Real(-4))` is `(0+2i)`), reproducing CMath's exact decision. | **Done** |
| Roots, exp & log | `Sqrt`, `Cbrt`, `Exp`, `Log` (optional base), `Log2`, `Log10` — mirroring `CMath.sqrt` / `cbrt` / `exp` / `log` / `log2` / `log10` on MRI's principal branch cuts. | **Done** |
| Trig & hyperbolic | `Sin` / `Cos` / `Tan`, `Sinh` / `Cosh` / `Tanh`, and the inverses `Asin` / `Acos` / `Atan` / `Atan2` / `Asinh` / `Acosh` / `Atanh` — the inverses built from this package's own `Log` and `Sqrt`, exactly as the cmath gem builds them. | **Done** |
| MRI branch cuts | Outside the real branch each function uses the same closed-form expression CMath's Ruby source uses, so the principal branch cuts and float results agree with `ruby -rcmath`. | **Done** |
| Differential oracle & coverage | Golden values captured from MRI 4.0.5 hold coverage at 100%; an oracle suite drives `ruby -rcmath` across a broad real / negative / out-of-domain / complex corpus; gofmt + go vet clean, green across all six 64-bit Go arches and three OSes. | **Done** |

## Documented out-of-scope boundaries

These are **deliberate**, recorded so the module's surface is unambiguous:

- **No interpreter.** The library implements the deterministic mathematics; it
  never runs arbitrary Ruby. Binding the results to a host's live
  `Float`/`Complex` objects is the consumer's job — that is why `rbgo` binds this
  module rather than the reverse.
- **Reference is reference Ruby (MRI).** Parity targets MRI 4.0.5's `cmath`; the
  differential oracle gates on `RUBY_VERSION >= "4.0"`.
- **Standalone & reusable.** The module has no dependency on the Ruby runtime;
  the dependency runs the other way.

See [Usage & API](api.md) for the surface and [Why pure Go](why.md) for the
deterministic/interpreter split.
