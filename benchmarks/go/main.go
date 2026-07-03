// Copyright (c) the go-ruby-cmath/cmath authors
// SPDX-License-Identifier: BSD-3-Clause
//
// Go driver: the same CMath workload as ruby/cmath.rb, over an identical
// deterministic corpus of real-and-complex arguments, exercised through the
// pure-Go go-ruby-cmath/cmath API. Each sub-benchmark applies one CMath function
// to every value in the corpus; the reported ns/op is the cost of one full pass
// over the corpus (N values). CHECK=1 emits a numeric digest instead of timing.
package main

import "github.com/go-ruby-cmath/cmath"

// N is the corpus size — kept identical to cmath.rb.
const N = 256

// corpus builds the shared deterministic input set. Every value uses exact
// binary fractions (/16 and /4) so the doubles are bit-identical to Ruby's.
// Even indices are real; odd indices are complex with a strictly non-zero
// imaginary part (so we never hit the complex-integer-0 cosmetic branch). Real
// values span negative and non-negative, so sqrt/log take both their real and
// complex branches within a single pass.
func corpus() []cmath.Number {
	xs := make([]cmath.Number, N)
	for i := 0; i < N; i++ {
		re := (float64(i) - 127.5) / 16.0 // -7.96875 .. 8.03125, never exactly 0
		im := float64((i%5)+1) / 4.0      // 0.25 .. 1.25, always non-zero
		if i%2 == 0 {
			xs[i] = cmath.Real(re)
		} else {
			xs[i] = cmath.Complex(re, im)
		}
	}
	return xs
}

// digest reduces a per-op result stream to two sums (real, imag) for the CHECK
// comparison against the MRI oracle.
func digest(xs []cmath.Number, fn func(cmath.Number) cmath.Number) (float64, float64) {
	var sr, si float64
	for _, z := range xs {
		r := fn(z)
		sr += r.Real
		si += r.Imag
	}
	return sr, si
}

func main() {
	xs := corpus()

	ops := []struct {
		label string
		fn    func(cmath.Number) cmath.Number
	}{
		{"sqrt", cmath.Sqrt},
		{"exp", cmath.Exp},
		{"log", func(z cmath.Number) cmath.Number { return cmath.Log(z) }},
		{"sin", cmath.Sin},
		{"cos", cmath.Cos},
	}

	for _, op := range ops {
		fn := op.fn
		sr, si := digest(xs, fn)
		check(op.label, sr, si)
		bench(op.label, 300, func() {
			for _, z := range xs {
				sink = fn(z)
			}
		})
	}
}
