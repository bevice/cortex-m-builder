#!/bin/sh
mkdir -p /src /build /artifacts
cd /build
cmake /src
cmake --build .
cp *.{bin,elf} /artifacts
 