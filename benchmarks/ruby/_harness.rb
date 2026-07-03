# frozen_string_literal: true
#
# Copyright (c) the go-ruby-cmath/cmath authors
# SPDX-License-Identifier: BSD-3-Clause
#
# Library-level micro-benchmark harness (Ruby side).
#
# bench(label, inner) { work } runs `WARM` untimed outer passes (to let YJIT /
# JRuby / TruffleRuby reach steady state), then `OUTER` timed passes of `inner`
# operations each, timed with a monotonic clock, and reports the BEST pass as
# nanoseconds per operation. Interpreter start-up is deliberately OUTSIDE the
# timed region: this isolates the operation itself, so the number is the library
# primitive's cost, not `ruby file.rb` process cost.
#
# When CHECK=1 the timed passes are skipped and check(label, re, im) emits a
# numeric digest of the whole result corpus, so run.sh can confirm this runtime
# agrees with the MRI oracle — within floating-point rounding — before timing.
#
# Output protocol (one line per sub-benchmark), consumed by run.sh:
#   RESULT\t<label>\t<ns_per_op>   or   CHECK\t<label>\t<sum_re>\t<sum_im>

OUTER = Integer(ENV.fetch("OUTER", "25"))
WARM  = Integer(ENV.fetch("WARM", "3"))
CHECK = !(ENV["CHECK"].nil? || ENV["CHECK"].empty?)

def bench(label, inner)
  return if CHECK

  WARM.times { inner.times { yield } }
  best = nil
  OUTER.times do
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    inner.times { yield }
    dt = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
    best = dt if best.nil? || dt < best
  end
  ns = (best / inner) * 1e9
  printf("RESULT\t%s\t%.1f\n", label, ns)
end

def check(label, sum_re, sum_im)
  printf("CHECK\t%s\t%.12g\t%.12g\n", label, sum_re, sum_im) if CHECK
end
