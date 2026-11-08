#!/bin/bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: enhance.sh INPUT OUTPUT.png [photo|artwork] [tile-size]

Run the bundled Real-ESRGAN macOS model at 4x. Input: PNG, JPEG or WebP.
photo uses the general model; artwork uses the illustration model.
The default tile size is 128. Existing output files are not overwritten.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then usage; exit 0; fi
if [[ $# -lt 2 || $# -gt 4 ]]; then usage >&2; exit 2; fi

task_input=$1
task_output=$2
task_model=${3:-photo}
task_tile=${4:-128}
case "$task_model" in
  photo) task_model_name=realesrgan-x4plus ;;
  artwork) task_model_name=realesrgan-x4plus-anime ;;
  *) echo 'Model must be photo or artwork.' >&2; exit 2 ;;
esac
if [[ ! "$task_tile" =~ ^[0-9]+$ ]] || { (( task_tile < 32 )) && (( task_tile != 0 )); }; then
  echo 'Tile size must be 0 or at least 32.' >&2; exit 2
fi
if [[ ! -f "$task_input" ]]; then echo 'Input file not found.' >&2; exit 2; fi
if [[ -e "$task_output" ]]; then echo 'Output already exists; choose a new name.' >&2; exit 2; fi
case "$task_output" in *.png|*.PNG) ;; *) echo 'Output must use .png.' >&2; exit 2 ;; esac

task_skill_dir="$(cd "$(dirname "$0")/.." && pwd -P)"
task_runtime="$task_skill_dir/assets/realesrgan"
if [[ "$(uname -s)" != Darwin || ! -x "$task_runtime/realesrgan-ncnn-vulkan" ]]; then
  echo 'The bundled Real-ESRGAN runtime requires macOS.' >&2; exit 1
fi
if [[ ! -d "$(dirname "$task_output")" ]]; then
  echo 'Output directory does not exist.' >&2; exit 2
fi
task_output_dir="$(cd "$(dirname "$task_output")" && pwd -P)"
task_output="$task_output_dir/$(basename "$task_output")"
task_work_dir="$(mktemp -d /tmp/upscale-anh-enhance.XXXXXXXX)"
trap 'rm -rf -- "$task_work_dir"' EXIT
# ncnn ignores JPEG EXIF orientation; normalize orientation and color first.
"$task_skill_dir/scripts/export-png.sh" --input "$task_input" --output "$task_work_dir/oriented.png" --native
"$task_runtime/realesrgan-ncnn-vulkan" -i "$task_work_dir/oriented.png" -o "$task_work_dir/enhanced.png" \
  -m "$task_runtime/models" -n "$task_model_name" -s 4 -t "$task_tile" -j 1:1:1
if [[ -e "$task_output" ]]; then echo 'Output appeared during processing; refusing to overwrite.' >&2; exit 2; fi
cp -n "$task_work_dir/enhanced.png" "$task_output"
echo "Saved enhanced image: $task_output"
