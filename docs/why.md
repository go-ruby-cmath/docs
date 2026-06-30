# Why pure Go

`go-ruby-cmath/cmath` reimplements Ruby's `CMath` standard library in **pure Go,
with cgo disabled**. The mathematics of CMath — the real-vs-complex branch test,
the closed-form complex expressions, the principal branch cuts — is **fully
deterministic and interpreter-independent**: given its inputs, the result is a
pure function of those inputs, with no live binding and no evaluation of arbitrary
Ruby. That is exactly the part that can — and should — live as a standalone Go
library, separate from the interpreter.

## A reusable library, bound by rbgo

This library is the deterministic core that backs Ruby's `CMath` in
[go-embedded-ruby](https://github.com/go-embedded-ruby/ruby). It is **standalone
and reusable** so that:

- any Go program can import `github.com/go-ruby-cmath/cmath` directly, with no
  Ruby runtime;
- the dependency runs the *other* way — `rbgo` binds this module as a native
  module (the same pattern as [go-ruby-regexp](https://github.com/go-ruby-regexp)
  and [go-ruby-yaml](https://github.com/go-ruby-yaml)), rather than this module
  depending on the interpreter;
- the behaviour is pinned by a **differential oracle** against the system
  `ruby -rcmath`, independent of any one consumer.

## What it is — and isn't

The mathematics needs **no interpreter**, so it lives here as pure Go. Binding
the results to a host's live `Float`/`Complex` objects is the host's job; this
library takes and returns a small, explicit value model — the
[`Number`](api.md#the-number-value-model) — the Go analogue of Ruby's
`Float`-or-`Complex`. Faithfulness to the gem is structural: every function uses
the **same real-vs-complex test** and the **same closed-form expression** the
`cmath` gem's Ruby source does (e.g. `Asin` from this package's own `Log` and
`Sqrt`, exactly as `CMath.asin` is), so results agree with the `ruby` binary to
floating-point rounding.

## Why pure Go matters here

Because the library is CGO-free and dependency-free, it:

- cross-compiles to every Go target with no C toolchain, and links into a single
  static binary;
- has **no dependency on the Ruby runtime** — the dependency runs the other way;
- can be differentially tested against `ruby -rcmath` wherever a `ruby` is on
  `PATH`, while the cross-arch lanes (where `ruby` is absent) still validate the
  library itself against golden values captured from MRI.

See [Usage & API](api.md) for the surface and [Roadmap](roadmap.md) for what is
in scope.
