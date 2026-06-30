# go-ruby-cmath documentation

**Ruby's `CMath` in pure Go — complex-aware sqrt / exp / log / trig, MRI-compatible, no cgo.**

`go-ruby-cmath/cmath` is a faithful, pure-Go (zero cgo) reimplementation of
Ruby's `CMath` standard library — the complex-aware trigonometric and
transcendental functions of MRI 4.0.5's `cmath` gem — matching reference Ruby
byte-for-byte. The module path is `github.com/go-ruby-cmath/cmath`.

CMath accepts real *or* complex arguments and returns a **real** result when the
input lies on the real branch of the function (`CMath.sqrt(4)` is `2.0`) and a
**complex** result otherwise (`CMath.sqrt(-4)` is `(0+2i)`). This library
reproduces that exact real-vs-complex decision and MRI's principal branch cuts
and float formulas — **without any Ruby runtime** — over a small explicit
[`Number`](api.md#the-number-value-model) value model. It is a CMath backend
bound into [go-embedded-ruby](https://github.com/go-embedded-ruby/ruby) by
`rbgo` as a native module, a standalone sibling of
[go-ruby-regexp](https://github.com/go-ruby-regexp),
[go-ruby-marshal](https://github.com/go-ruby-marshal) and
[go-ruby-yaml](https://github.com/go-ruby-yaml). The dependency runs the other
way: this library has **no dependency on the Ruby runtime**.

!!! success "Status: complete — MRI byte-exact"
    Every function mirrors the same-named method of Ruby's `CMath` — `Sqrt` / `Cbrt` / `Exp` / `Log` / `Log2` / `Log10`, the trig and hyperbolic families and their inverses — taking and returning the `Number` real-or-complex value model. Validated by a **differential oracle** against the system `ruby -rcmath` across a real / negative / out-of-domain / complex corpus, at 100% coverage, `gofmt` + `go vet` clean, CI green across the six 64-bit Go targets and three OSes.

## Quick taste

```go
cmath.Sqrt(cmath.Real(4))    // real 2.0
cmath.Sqrt(cmath.Real(-4))   // complex (0+2i)
cmath.Log(cmath.Real(-1))    // complex (0+πi)
cmath.Asin(cmath.Real(2))    // complex (1.5707963267948966-1.3169578969248166i)
cmath.Cbrt(cmath.Real(-8))   // complex (1+1.7320508075688772i)
```

## Repositories

| Repo | What it is |
| --- | --- |
| [`cmath`](https://github.com/go-ruby-cmath/cmath) | the library — Ruby's CMath in pure Go |
| [`docs`](https://github.com/go-ruby-cmath/docs) | this documentation site (MkDocs Material, versioned with mike) |
| [`go-ruby-cmath.github.io`](https://github.com/go-ruby-cmath/go-ruby-cmath.github.io) | the organization landing page (Hugo) |
| [`brand`](https://github.com/go-ruby-cmath/brand) | logo and brand assets |

## Principles

- **Pure Go, `CGO_ENABLED=0`** — trivial cross-compilation, a single static
  binary, no C toolchain.
- **MRI byte-exact.** The real-vs-complex shape and the float components match
  reference Ruby, validated by a differential oracle against `ruby -rcmath`.
- **Same expressions as the gem.** Outside the real branch each function uses the
  same closed-form expression CMath's Ruby source uses, so the principal branch
  cuts agree.
- **Standalone & reusable.** Extracted from rbgo's internals; no dependency on
  the Ruby runtime — the dependency runs the other way.
- **100% test coverage** is the target, enforced as a CI gate, across 6 arches
  and 3 OSes.

## Where to go next

- [Why pure Go](why.md) — why CMath's mathematics is deterministic enough to live
  as a standalone, interpreter-independent Go library.
- [Usage & API](api.md) — the `Number` value model, the full function table, and
  worked examples.
- [Roadmap](roadmap.md) — what is done and what is downstream by design.

Source lives at [github.com/go-ruby-cmath/cmath](https://github.com/go-ruby-cmath/cmath).
