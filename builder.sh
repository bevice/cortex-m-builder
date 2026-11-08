#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f /src/CMakeLists.txt ]]; then
    echo "Mount a CMake project containing CMakeLists.txt at /src" >&2
    exit 1
fi

mkdir -p /build /artifacts
export CMAKE_BUILD_PARALLEL_LEVEL="${CMAKE_BUILD_PARALLEL_LEVEL:-$(nproc)}"

# Keep legacy whitespace-separated options; use positional arguments for values
# containing spaces. Disable glob expansion and never evaluate options as code.
set -f
# shellcheck disable=SC2086
cmake -S /src -B /build ${CMAKE_PARAMS:-} "$@"
# shellcheck disable=SC2086
cmake --build /build ${CMAKE_BUILD_PARAMS:-}

cd /build
mapfile -d '' artifacts < <(find . -type d -name CMakeFiles -prune -o -type f \( \
    -name '*.bin' -o -name '*.elf' -o -name '*.hex' -o -name '*.map' \
    \) -print0)
if (( ${#artifacts[@]} == 0 )); then
    echo "Build succeeded, but no .bin, .elf, .hex or .map artifacts were found" >&2
    exit 1
fi
# Preserve subdirectories so equal basenames do not overwrite each other.
cp --parents -- "${artifacts[@]}" /artifacts/
