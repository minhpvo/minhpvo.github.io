#!/usr/bin/env bash
# Encrypt the plaintext report into the password-protected page that gets published.
#
#   eval_report.src.html  (plaintext, gitignored — edit this one)
#        |  ./encrypt-report.sh
#        v
#   eval_report.html      (StatiCrypt output, committed & published)
#
# You will be prompted for the password. Use the same one as before so existing
# links keep working. The salt in .staticrypt.json is reused automatically.

set -euo pipefail
cd "$(dirname "$0")"

SRC="eval_report.src.html"
OUT="eval_report.html"

if [ ! -f "$SRC" ]; then
  echo "error: $SRC not found. It holds the plaintext report and is gitignored," >&2
  echo "       so it only exists locally. Restore it before encrypting." >&2
  exit 1
fi

if head -3 "$SRC" | grep -q staticrypt; then
  echo "error: $SRC is already encrypted. Refusing to double-encrypt." >&2
  exit 1
fi

# StatiCrypt has no single-file output flag: it writes <basename> into the -d
# directory. So encrypt into a scratch dir, then move the result into place.
#
# --short: the existing password is under StatiCrypt's recommended 14 chars, which
# would otherwise trigger an interactive confirmation prompt.
TMPDIR_ENC=".staticrypt-out"
rm -rf "$TMPDIR_ENC"
npx --yes staticrypt "$SRC" -d "$TMPDIR_ENC" --short

GENERATED="$TMPDIR_ENC/$SRC"
if [ ! -f "$GENERATED" ]; then
  echo "error: expected $GENERATED, but StatiCrypt produced:" >&2
  ls -la "$TMPDIR_ENC" >&2
  exit 1
fi

if ! head -3 "$GENERATED" | grep -q staticrypt; then
  echo "error: $GENERATED does not look encrypted. Leaving $OUT untouched." >&2
  exit 1
fi

mv "$GENERATED" "$OUT"
rm -rf "$TMPDIR_ENC"

echo
echo "Encrypted $SRC -> $OUT"
echo "Next: git add eval_report.html && git commit && git push"
