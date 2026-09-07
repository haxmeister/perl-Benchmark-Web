#!/bin/sh
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE="$HERE/.source"
BUILD="$HERE/.build"
PREFIX="$HERE/.local"
REF=${1:-master}

for command in git cmake cc pkg-config; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "missing required build command: $command" >&2
        exit 1
    fi
done

JOBS=1
if command -v nproc >/dev/null 2>&1; then
    JOBS=$(nproc)
fi

rm -rf "$SOURCE" "$BUILD" "$PREFIX"

echo "==> cloning H2O ($REF)"
git clone \
    --depth 1 \
    --branch "$REF" \
    --recurse-submodules \
    --shallow-submodules \
    https://github.com/h2o/h2o.git \
    "$SOURCE"

echo "==> configuring target-local libh2o-evloop"
cmake -S "$SOURCE" -B "$BUILD" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DWITHOUT_LIBS=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DWITH_MRUBY=OFF \
    -DWITH_BROTLI=OFF \
    -DWITH_AEGIS=OFF \
    -DWITH_IO_URING=OFF \
    -DWITH_FUSION=OFF

echo "==> building H2O"
cmake --build "$BUILD" --parallel "$JOBS"

echo "==> installing into $PREFIX"
cmake --install "$BUILD"

PC=''
for candidate in \
    "$PREFIX/lib/pkgconfig/libh2o-evloop.pc" \
    "$PREFIX/lib64/pkgconfig/libh2o-evloop.pc" \
    "$PREFIX"/lib/*/pkgconfig/libh2o-evloop.pc
 do
    if [ -f "$candidate" ]; then
        PC=$candidate
        break
    fi
done

if [ -z "$PC" ]; then
    echo "H2O installed, but libh2o-evloop.pc was not found under $PREFIX" >&2
    exit 1
fi

echo "==> installed $(dirname "$PC")/libh2o-evloop.pc"
echo "==> verify from benchmarks/http with:"
echo "    perl servers/h2o/server.pl probe"
echo "    perl run.pl --servers=h2o --smoke --strict"
