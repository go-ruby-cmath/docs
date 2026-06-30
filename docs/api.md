# Usage & API

The public API lives at the module root (`github.com/go-ruby-cmath/cmath`). It is
**Ruby-shaped but Go-idiomatic**: every function mirrors the same-named method of
Ruby's `CMath` module, while the surface follows Go conventions — value types, no
global state, an explicit `Number` model instead of duck-typed Ruby objects.

!!! success "Status: implemented"
    The library is built and importable as `github.com/go-ruby-cmath/cmath`,
    bound into `rbgo` as a native module; see [Roadmap](roadmap.md).

## Install

```sh
go get github.com/go-ruby-cmath/cmath
```

## The `Number` value model

A `Number` is a real-or-complex value, the Go analogue of a Ruby
`Float`-or-`Complex`:

```go
n := cmath.Real(4)         // a real argument (Ruby Integer / Float)
z := cmath.Complex(0, 1)   // a complex argument (Ruby Complex)

r := cmath.Sqrt(n)         // r.IsComplex == false, r.Real == 2.0
c := cmath.Sqrt(cmath.Real(-4))
                           // c.IsComplex == true, c.Real == 0, c.Imag == 2.0
```

`cmath.Complex(re, 0)` stays complex even with a zero imaginary part, matching
Ruby: `Complex(1, 0).real?` is `false`, so CMath treats it as complex. The
mathematics of CMath — the real-vs-complex branch test, the closed-form complex
expressions, the principal branch cuts — is fully deterministic and needs **no
interpreter**, so it lives here as pure Go. Binding the results to a host's live
`Float`/`Complex` objects is the host's job.

## Functions

Every function mirrors the same-named method of Ruby's `CMath`, taking and
returning `Number`:

| Go | Ruby | Real branch (returns real) |
| --- | --- | --- |
| `Sqrt(z)` | `CMath.sqrt` | real `z >= 0` |
| `Exp(z)` | `CMath.exp` | real `z` |
| `Log(z[, base])` | `CMath.log` | real `z >= 0` and real `base >= 0` |
| `Log2(z)` | `CMath.log2` | real `z >= 0` |
| `Log10(z)` | `CMath.log10` | real `z >= 0` |
| `Cbrt(z)` | `CMath.cbrt` | real `z >= 0` |
| `Sin/Cos/Tan(z)` | `CMath.sin/cos/tan` | real `z` |
| `Sinh/Cosh/Tanh(z)` | `CMath.sinh/cosh/tanh` | real `z` |
| `Asin(z)` | `CMath.asin` | real `z` in `[-1, 1]` |
| `Acos(z)` | `CMath.acos` | real `z` in `[-1, 1]` |
| `Atan(z)` | `CMath.atan` | real `z` |
| `Atan2(y, x)` | `CMath.atan2` | real `y` and real `x` |
| `Asinh(z)` | `CMath.asinh` | real `z` |
| `Acosh(z)` | `CMath.acosh` | real `z >= 1` |
| `Atanh(z)` | `CMath.atanh` | real `z` in `[-1, 1]` |

Constructors and accessors round out the surface:

```go
func Real(x float64) Number       // a real argument
func Complex(re, im float64) Number // a complex argument (stays complex)
```

Outside the real branch each function returns the complex result, computed with
the **same closed-form expression** CMath uses — `Asin`, for instance, is built
from this package's own `Log` and `Sqrt`, exactly as `CMath.asin` is — so the
branch cuts agree with MRI.

## Worked example

A few representative results, matching `ruby -rcmath`:

```go
cmath.Sqrt(cmath.Real(4))    // real 2.0
cmath.Sqrt(cmath.Real(-4))   // complex (0+2i)
cmath.Log(cmath.Real(-1))    // complex (0+πi)
cmath.Asin(cmath.Real(2))    // complex (1.5707963267948966-1.3169578969248166i)
cmath.Cbrt(cmath.Real(-8))   // complex (1+1.7320508075688772i)
```

## MRI conformance

Correctness is defined by reference Ruby. A **differential oracle** drives the
real `ruby -rcmath` binary across a broad real / negative / out-of-domain /
complex corpus and confirms genuine MRI parity — comparing both the exact
real-vs-complex shape and the float components to a tight tolerance, not
approximated from memory. The oracle tests skip themselves where `ruby` is absent
or older than 4.0 (the Windows and qemu cross-arch lanes), so the cross-arch
builds still validate the library.

## Relationship to Ruby

`go-ruby-cmath/cmath` is **standalone and reusable**, and is a backend bound into
[go-embedded-ruby](https://github.com/go-embedded-ruby/ruby) by `rbgo` as a
native module — the same way [go-ruby-regexp](https://github.com/go-ruby-regexp)
and [go-ruby-yaml](https://github.com/go-ruby-yaml) are bound. The dependency
runs the other way: this library has no dependency on the Ruby runtime.
