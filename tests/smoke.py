"""Docker integration checks: python tests/smoke.py [image]."""
import pathlib
import subprocess
import sys
import tempfile

IMAGE = sys.argv[1] if len(sys.argv) > 1 else "bevice/cortex-m-builder:2026-11"


def check(project, *, env=(), args=(), expected=(), failure=False, stale=False):
    with tempfile.TemporaryDirectory(prefix="cortex-builder-") as tmp:
        root = pathlib.Path(tmp)
        for name in ("src", "build", "artifacts"):
            (root / name).mkdir()
        for name, content in project.items():
            target = root / "src" / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8")
        if stale:
            (root / "build" / "stale.elf").write_bytes(b"old firmware")
        cmd = ["docker", "run", "--rm"]
        for name in ("src", "build", "artifacts"):
            cmd += ["-v", f"{root / name}:/{name}" + (":ro" if name == "src" else "")]
        for value in env:
            cmd += ["-e", value]
        result = subprocess.run(cmd + [IMAGE, *args], capture_output=True, text=True)
        if failure:
            assert result.returncode != 0, result.stdout
            assert not list((root / "artifacts").rglob("*")), "Published artifacts after failure"
        else:
            assert result.returncode == 0, result.stdout + result.stderr
            for name in expected:
                assert (root / "artifacts" / name).stat().st_size > 0, name
            assert not list((root / "artifacts").rglob("CMakeFiles")), "Copied compiler probes"
            cache = (root / "build" / "CMakeCache.txt").read_text()
            generator = "Unix Makefiles" if "CMAKE_GENERATOR=Unix Makefiles" in env else "Ninja"
            assert f"CMAKE_GENERATOR:INTERNAL={generator}" in cache


FIRMWARE = {
    "CMakeLists.txt": r'''
cmake_minimum_required(VERSION 3.17)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)
project(smoke C CXX)
if(NOT MESSAGE STREQUAL "hello world")
    message(FATAL_ERROR "Argument with spaces was not preserved")
endif()
add_executable(firmware.elf main.c helper.cpp)
target_compile_options(firmware.elf PRIVATE -mcpu=cortex-m3 -mthumb)
target_link_options(firmware.elf PRIVATE -mcpu=cortex-m3 -mthumb
    --specs=nano.specs --specs=nosys.specs -nostartfiles -Wl,-e,main
    "-Wl,-Map=${CMAKE_BINARY_DIR}/firmware.map")
set_target_properties(firmware.elf PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/nested dir")
add_custom_command(TARGET firmware.elf POST_BUILD
    COMMAND arm-none-eabi-objcopy -O binary "$<TARGET_FILE:firmware.elf>" "${CMAKE_BINARY_DIR}/nested dir/firmware.bin"
    COMMAND arm-none-eabi-objcopy -O ihex "$<TARGET_FILE:firmware.elf>" "${CMAKE_BINARY_DIR}/nested dir/firmware.hex"
    VERBATIM)
''',
    "main.c": "extern int helper(void); int main(void) { return helper(); }\n",
    "helper.cpp": '#include <cstdint>\nextern "C" int helper() { return std::uint32_t{42}; }\n',
}

for generator in ("Ninja", "Unix Makefiles"):
    check(FIRMWARE, env=(f"CMAKE_GENERATOR={generator}", "CMAKE_PARAMS=-DCMAKE_BUILD_TYPE=Debug",
                         "CMAKE_BUILD_PARAMS=--target firmware.elf", "CMAKE_BUILD_PARALLEL_LEVEL=2"),
          args=("-DMESSAGE=hello world",),
          expected=("nested dir/firmware.elf", "nested dir/firmware.bin",
                    "nested dir/firmware.hex", "firmware.map"))
    print(f"PASS ARM C/C++, nano.specs, artifacts and options: {generator}")

check({}, failure=True)
print("PASS missing project")
check({"CMakeLists.txt": 'cmake_minimum_required(VERSION 3.17)\nmessage(FATAL_ERROR "expected")\n'},
      failure=True, stale=True)
print("PASS configuration failure does not publish stale firmware")
check({"CMakeLists.txt": 'cmake_minimum_required(VERSION 3.17)\nproject(broken C)\nadd_executable(broken main.c)\n',
       "main.c": '#error expected compilation failure\n'}, failure=True, stale=True)
print("PASS compilation failure does not publish stale firmware")
check({"CMakeLists.txt": 'cmake_minimum_required(VERSION 3.17)\nproject(empty NONE)\n'}, failure=True)
print("PASS missing artifacts")
