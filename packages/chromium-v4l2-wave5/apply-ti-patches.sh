#!/usr/bin/env bash
set -euo pipefail

SRC="${CHROMIUM_SRC:-/work/chromium/src}"
ROOT="$(cd "$(dirname "$0")" && pwd)"

cd "$SRC"

echo "Chromium: $(git describe --always --dirty)"
echo "TI V4L2/Wave5 yamalari uygulanıyor..."

for patch in "$ROOT"/patches/*.patch; do
    echo "=== $(basename "$patch") ==="
    # Kit Windows üzerinden taşınmışsa CRLF, git apply tarafından bozuk hunk
    # olarak yorumlanabilir.
    sed -i 's/\r$//' "$patch"
    if git apply --check "$patch"; then
        git apply "$patch"
    elif git apply --reverse --check "$patch"; then
        echo "Zaten uygulanmis."
    else
        echo "Yama bu Chromium revizyonuna temiz uygulanamadi: $patch" >&2
        echo "Chromium 152 API degisikligi icin manuel rebase gerekiyor." >&2
        exit 1
    fi
done

echo "Tum TI yamalari uygulandi."
git status --short
