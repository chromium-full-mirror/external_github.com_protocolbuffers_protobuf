#!/bin/bash
# Protocol Buffers - Google's data interchange format
# Copyright 2026 Google LLC
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file or at
# https://developers.google.com/open-source/licenses/bsd
#
# Writes one shard of the targets matched by a set of Bazel target patterns to a
# file, for use with `bazel test --target_pattern_file=<file>`.
#
# Usage: shard_targets.sh <shard (1-based)> <num_shards> <output_file> <pattern>...
#
# Matches what `bazel test <pattern>...` would select: all rule targets under
# the patterns, minus targets tagged "manual". Combine with
# --skip_incompatible_explicit_targets so platform-incompatible targets are
# skipped the same way they are for wildcard patterns.

set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <shard> <num_shards> <output_file> <pattern>..." >&2
  exit 1
fi

shard="$1"
num_shards="$2"
output="$3"
shift 3

query="let t = set($*) in \$t except attr(tags, '\\bmanual\\b', \$t)"

# shellcheck disable=SC2086
bazelisk ${BAZEL_STARTUP_FLAGS:-} query "${query}" --output=label \
  | tr -d '\r' \
  | sort \
  | awk -v n="${num_shards}" -v s="${shard}" 'NR % n == s - 1' \
  > "${output}"

echo "Shard ${shard}/${num_shards}: $(wc -l < "${output}" | tr -d ' ') targets for: $*"
