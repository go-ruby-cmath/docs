// Copyright (c) the go-ruby-cmath/cmath authors
// SPDX-License-Identifier: BSD-3-Clause
//
// Library-level micro-benchmark harness (Go side). Mirrors _harness.rb exactly:
// WARM untimed outer passes, then OUTER timed passes of `inner` ops each, best
// pass reported as ns/op. Emits the same RESULT protocol run.sh consumes. When
// CHECK=1 it instead emits one CHECK line per benchmark (a deterministic numeric
// digest of the whole corpus of results), so the Go output can be verified equal
// to the MRI oracle — within floating-point rounding — before any timing.
package main

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

var (
	outerN  = envInt("OUTER", 25)
	warmN   = envInt("WARM", 3)
	checkOn = os.Getenv("CHECK") != ""
	// sink defeats dead-code elimination of the timed work.
	sink any
)

func envInt(k string, def int) int {
	if v := os.Getenv(k); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return def
}

// bench runs a timed micro-benchmark: WARM untimed passes, then OUTER timed
// passes of `inner` invocations of fn, reporting the best pass as ns/op.
func bench(label string, inner int, fn func()) {
	if checkOn {
		return
	}
	for i := 0; i < warmN; i++ {
		for j := 0; j < inner; j++ {
			fn()
		}
	}
	var best time.Duration
	for o := 0; o < outerN; o++ {
		t0 := time.Now()
		for j := 0; j < inner; j++ {
			fn()
		}
		dt := time.Since(t0)
		if o == 0 || dt < best {
			best = dt
		}
	}
	ns := float64(best.Nanoseconds()) / float64(inner)
	fmt.Printf("RESULT\t%s\t%.1f\n", label, ns)
}

// check emits a corpus digest for the given label: the summed real and imaginary
// parts of every result. run.sh compares this to the MRI oracle's digest (to a
// floating-point tolerance) before trusting any timing.
func check(label string, sumRe, sumIm float64) {
	if checkOn {
		fmt.Printf("CHECK\t%s\t%.12g\t%.12g\n", label, sumRe, sumIm)
	}
}
