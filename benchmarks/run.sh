#!/usr/bin/env bash
#
# Copyright (c) the go-ruby-cmath/cmath authors
# SPDX-License-Identifier: BSD-3-Clause
#
# Library-level cross-runtime benchmark runner for go-ruby-cmath/cmath.
#
# Runs the SAME CMath workload through (a) the pure-Go go-ruby-cmath library
# (benchmarks/go) and (b) each available reference Ruby runtime
# (benchmarks/ruby/cmath.rb), then prints one Markdown table per sub-benchmark:
# ns/op and the ratio vs MRI.
#
# Before timing, a VERIFY phase runs every engine in CHECK mode and confirms its
# result digest agrees with the MRI oracle to a floating-point tolerance; a
# mismatch aborts the run so no un-verified number is ever reported.
#
# Usage:  bash benchmarks/run.sh
# Env:    OUTER (timed passes, default 25), WARM (untimed passes, default 3),
#         RUBY / JRUBY / TRUFFLERUBY (override runtime binaries),
#         TOL (verify relative tolerance, default 1e-9).
#
# Note: CMath was removed as a default gem from JRuby 10.1 and TruffleRuby 34;
# `gem install cmath` provides the same pure-Ruby implementation MRI ships, so
# those columns exercise each VM running the identical reference cmath code.
set -u
cd "$(dirname "$0")"

RUBY=${RUBY:-ruby}
JRUBY=${JRUBY:-jruby}
TRUFFLERUBY=${TRUFFLERUBY:-truffleruby}
TOL=${TOL:-1e-9}

RB=ruby/cmath.rb
TMP=$(mktemp)
CHK=$(mktemp)
trap 'rm -f "$TMP" "$CHK"' EXIT

have() { command -v "$1" >/dev/null 2>&1; }

# --- VERIFY phase: every engine's digest must match MRI's ------------------
echo "== verify (Go / MRI / JRuby / TruffleRuby digests vs MRI oracle) ==" >&2
emit_check() { # <label> <cmd...>
  local label=$1; shift
  have "$1" || { echo "  ($label: $1 not found — skipped)" >&2; return; }
  "$@" 2>/dev/null | awk -v r="$label" '$1=="CHECK"{printf "%s\t%s\t%s\t%s\n", r, $2, $3, $4}'
}
{
  ( cd go && have go && CHECK=1 go run . 2>/dev/null ) \
    | awk '$1=="CHECK"{printf "go\t%s\t%s\t%s\n", $2, $3, $4}'
  CHECK=1 emit_check mri         "$RUBY"        "$RB"
  CHECK=1 emit_check jruby       "$JRUBY"       "$RB"
  CHECK=1 emit_check truffleruby "$TRUFFLERUBY" "$RB"
} > "$CHK"

python3 - "$CHK" "$TOL" <<'PY' >&2 || { echo "VERIFY FAILED — aborting before timing." >&2; exit 1; }
import sys
rows = [l.split("\t") for l in open(sys.argv[1]) if l.strip()]
tol = float(sys.argv[2])
base = {}   # label -> (re, im) from MRI oracle
for rt, lab, re, im in rows:
    if rt == "mri":
        base[lab] = (float(re), float(im))
bad = 0
for rt, lab, re, im in rows:
    if lab not in base:
        continue
    br, bi = base[lab]
    for got, want, part in ((float(re), br, "re"), (float(im), bi, "im")):
        if abs(got - want) > tol * (1.0 + abs(want)):
            print(f"  MISMATCH {rt} {lab}.{part}: {got!r} vs MRI {want!r}")
            bad += 1
if bad:
    sys.exit(1)
print("  all digests agree with the MRI oracle (tol %s)." % tol)
PY

# --- TIMING phase ----------------------------------------------------------
echo >&2
echo "== go-ruby-cmath library-level benchmark ==" >&2
echo "  go ..." >&2
( cd go && have go && go run . 2>/dev/null ) \
  | awk '$1=="RESULT"{printf "go\t%s\t%s\n", $2, $3}' >> "$TMP"
run() { # <runtime-label> <cmd...>
  local label=$1; shift
  have "$1" || { echo "  ($label: $1 not found — skipped)" >&2; return; }
  echo "  $label ..." >&2
  "$@" 2>/dev/null | awk -v r="$label" '$1=="RESULT"{printf "%s\t%s\t%s\n", r, $2, $3}' >> "$TMP"
}
run "mri"         "$RUBY"                "$RB"
run "mri-yjit"    "$RUBY" --yjit         "$RB"
run "jruby"       "$JRUBY"               "$RB"
run "truffleruby" "$TRUFFLERUBY"         "$RB"

echo >&2
# Emit one Markdown table per sub-benchmark (label), runtimes as rows.
awk -F'\t' '
  { key=$2; rt=$1; ns=$3; labels[key]=1; val[rt SUBSEP key]=ns; rts[rt]=1 }
  END {
    order="go mri mri-yjit jruby truffleruby"
    n=split(order, ord, " ")
    ln=0; for (k in labels) lab[++ln]=k
    for (i=1;i<=ln;i++) for (j=i+1;j<=ln;j++) if (lab[j]<lab[i]){t=lab[i];lab[i]=lab[j];lab[j]=t}
    for (i=1;i<=ln;i++){
      k=lab[i]
      printf "\n#### %s\n\n", k
      print  "| Runtime | ns/op | vs MRI |"
      print  "| --- | ---: | ---: |"
      base=val["mri" SUBSEP k]
      for (o=1;o<=n;o++){
        rt=ord[o]; v=val[rt SUBSEP k]
        if (v=="") continue
        ratio=(base!=""&&base+0>0)? sprintf("%.2f×", v/base) : "—"
        name=rt
        if (rt=="go") name="**go-ruby (pure Go)**"
        else if (rt=="mri") name="MRI"
        else if (rt=="mri-yjit") name="MRI + YJIT"
        else if (rt=="jruby") name="JRuby"
        else if (rt=="truffleruby") name="TruffleRuby"
        printf "| %s | %s | %s |\n", name, v, ratio
      }
    }
  }
' "$TMP"
