# frozen_string_literal: true
# SPDX-License-Identifier: BSD-3-Clause
#
# Reference workload: the same CMath corpus and operations as the Go driver in
# ../go, run through each Ruby runtime's own pure-Ruby `cmath`. Even indices are
# real Floats, odd indices are Complex with a non-zero imaginary part; the real
# axis spans negative and non-negative values so sqrt/log take both branches.
require "cmath"
require_relative "_harness"

N = 256
xs = (0...N).map do |i|
  re = (i - 127.5) / 16.0     # -7.96875 .. 8.03125, never exactly 0
  im = ((i % 5) + 1) / 4.0    # 0.25 .. 1.25, always non-zero
  i.even? ? re : Complex(re, im)
end

ops = [
  ["sqrt", ->(z) { CMath.sqrt(z) }],
  ["exp",  ->(z) { CMath.exp(z) }],
  ["log",  ->(z) { CMath.log(z) }],
  ["sin",  ->(z) { CMath.sin(z) }],
  ["cos",  ->(z) { CMath.cos(z) }],
]

ops.each do |label, fn|
  sum_re = 0.0
  sum_im = 0.0
  xs.each do |z|
    r = fn.call(z)
    sum_re += r.real
    sum_im += r.imaginary
  end
  check(label, sum_re, sum_im)
  bench(label, 300) { xs.each { |z| fn.call(z) } }
end
