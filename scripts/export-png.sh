#!/bin/bash
set -euo pipefail
task_script_dir="$(cd "$(dirname "$0")" && pwd -P)"
if [[ "$(uname -s)" != Darwin ]] || ! command -v swiftc >/dev/null 2>&1; then
  echo 'This exporter requires macOS and the Swift compiler.' >&2
  exit 1
fi
task_build_dir="$(mktemp -d /tmp/upscale-anh.XXXXXXXX)"
trap 'rm -rf -- "$task_build_dir"' EXIT
swiftc -O -module-cache-path "$task_build_dir/swift-cache" "$task_script_dir/export-png.swift" -o "$task_build_dir/export-png"
"$task_build_dir/export-png" "$@"
