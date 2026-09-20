#!/bin/sh
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE="$HERE/.source"
CORE="$SOURCE/core"
HTTP="$SOURCE/http"
LOCAL="$HERE/.local"
HTTP_REF=${1:-main}
CORE_REF=${2:-main}

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

echo "==> cloning Linux::Event ($CORE_REF)"
git clone --depth 1 --branch "$CORE_REF" \
    https://github.com/haxmeister/perl-linux-event.git \
    "$CORE"

echo "==> installing Linux::Event into $LOCAL"
"$PERL" "$CPANM" \
    --notest \
    --local-lib-contained "$LOCAL" \
    "$CORE"

LOCAL_LIB="$LOCAL/lib/perl5"
"$PERL" -I"$LOCAL_LIB" \
    -MLinux::Event \
    -Mversion \
    -e 'die "Linux::Event 0.116 or newer is required\n" if version->parse($Linux::Event::VERSION) < version->parse("0.116"); print "Linux::Event $Linux::Event::VERSION\n"'

echo "==> cloning Linux::Event::HTTP ($HTTP_REF)"
git clone --depth 1 --branch "$HTTP_REF" \
    https://github.com/haxmeister/perl-Linux-Event-HTTP.git \
    "$HTTP"

echo "==> installing Linux::Event::HTTP prerequisites"
PERL5LIB="$LOCAL_LIB" "$PERL" "$CPANM" \
    --notest \
    --local-lib-contained "$LOCAL" \
    --installdeps "$HTTP"

echo "==> building Linux::Event::HTTP against target-local Linux::Event"
(
    cd "$HTTP"
    PERL5LIB="$LOCAL_LIB" "$PERL" Makefile.PL
    PERL5LIB="$LOCAL_LIB" make -j"$JOBS"
)

echo "==> source revisions"
echo "Linux::Event      $(git -C "$CORE" rev-parse HEAD)"
echo "Linux::Event::HTTP $(git -C "$HTTP" rev-parse HEAD)"

echo "==> verifying target-local benchmark runtime"
"$PERL" "$HERE/server.pl" probe
"$PERL" "$HERE/server.pl" version

echo "==> target-local Linux::Event::HTTP benchmark is ready"
echo "==> run from benchmarks/http with:"
echo "    perl run.pl --servers=linuxevent --smoke --strict"
