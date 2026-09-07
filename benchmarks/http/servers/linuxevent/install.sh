#!/bin/sh
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE="$HERE/.source"
HTTP="$SOURCE/http"
LOCAL="$HERE/.local"
HTTP_REF=${1:-main}

for command in git perl make cc cpanm; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "missing required build command: $command" >&2
        exit 1
    fi
done

PERL=$(command -v perl)
CPANM=$(command -v cpanm)
JOBS=1
if command -v nproc >/dev/null 2>&1; then
    JOBS=$(nproc)
fi

rm -rf "$SOURCE" "$LOCAL"
mkdir -p "$SOURCE"

echo "==> installing Linux::Event from CPAN into $LOCAL"
"$PERL" "$CPANM" \
    --notest \
    --local-lib-contained "$LOCAL" \
    Linux::Event

LOCAL_LIB="$LOCAL/lib/perl5"
"$PERL" -I"$LOCAL_LIB" \
    -MLinux::Event \
    -Mversion \
    -e 'die "Linux::Event 0.112 or newer is required\n" if version->parse($Linux::Event::VERSION) < version->parse("0.112"); print "Linux::Event $Linux::Event::VERSION\n"'

echo "==> cloning Linux::Event::Net::HTTP ($HTTP_REF)"
git clone --depth 1 --branch "$HTTP_REF" \
    https://github.com/haxmeister/perl-Linux-Event-Net-HTTP.git \
    "$HTTP"

echo "==> building Linux::Event::Net::HTTP against target-local Linux::Event"
(
    cd "$HTTP"
    "$PERL" -I"$LOCAL_LIB" Makefile.PL
    make -j"$JOBS"
)

echo "==> verifying target-local benchmark runtime"
"$PERL" "$HERE/server.pl" probe
"$PERL" "$HERE/server.pl" version

echo "==> target-local Linux::Event HTTP benchmark is ready"
echo "==> run from benchmarks/http with:"
echo "    perl run.pl --servers=linuxevent --smoke --strict"
