#!/bin/sh
#info: Repack fastpkg package, will only run once

set -e

TMP_DIR="/tmp"
LOCK_FILE="$TMP_DIR/repack-fastpkg.lock"
FILE_TMP="$TMP_DIR/fastpkg.deb"

error() {
    rm -f "$LOCK_FILE"
    echo "ERROR: $1" >&2
    exit 1
}

# skip, already repacked
if [ -f "$FILE_TMP" ]; then
    echo "skip, already repacked"
    exit 0
fi

# wait if another process is running
COUNTER=0
while [ -f "$LOCK_FILE" ]; do
    COUNTER=$((COUNTER + 1))
    sleep 1
    [ "$COUNTER" -gt 30 ] &&
        error "lock file $LOCK_FILE exists more than 30 seconds"
done
touch "$LOCK_FILE" || error "touch $LOCK_FILE failed"

# can't specify a folder for dpkg-repack
cd "$TMP_DIR" || error "cd /tmp failed"
# repack fastpkg
REPACK=$(fakeroot -u dpkg-repack fastpkg) || error "dpkg-repack fastpkg failed"
# verify repack
if echo "$REPACK" | grep -q "dpkg-deb: building package"; then
    :
else
    error "dpkg-repack fastpkg failed"
fi

# move repacked file
PACKAGE=$(find "$TMP_DIR" -maxdepth 1 -type f -name "fastpkg_*.deb") ||
    error "find fastpkg_*.deb failed"
if [ -n "$PACKAGE" ]; then
    mv -f "$PACKAGE" "$FILE_TMP" || error "mv $PACKAGE $FILE_TMP failed"
else
    error "file $FILE_TMP not found"
fi

rm -f "$LOCK_FILE"
