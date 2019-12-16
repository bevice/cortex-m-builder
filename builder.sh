#!/bin/sh
mkdir -p /src /build /artifacts
cd /build
cmake ${CMAKE_PARAMS} /src
cmake --build . ${CMAKE_BUILD_PARAMS}
cp *.bin /artifacts
cp *.elf /artifacts
 