# Line-coverage gate for lib/domain and lib/data, excluding generated *.g.dart.
# Usage: awk -v min=80 -f coverage_gate.awk coverage/lcov.info
# Accepts relative or absolute, forward- or back-slashed SF: paths.
/^SF:/ {
  f = substr($0, 4)
  keep = (f ~ /lib[\/\\](domain|data)[\/\\]/) && (f !~ /\.g\.dart$/)
}
/^DA:/ && keep {
  split(substr($0, 4), a, ",")
  total++
  if (a[2] > 0) hit++
}
END {
  if (min == "") min = 80
  pct = total ? 100 * hit / total : 0
  printf "domain+data line coverage: %.1f%% (%d/%d lines, gate %d%%)\n", pct, hit, total, min
  exit (total > 0 && pct >= min) ? 0 : 1
}
