#!/bin/zsh
# Master Quality Gate for Kite macOS (BAMA Standard)
# Runs full test suite, grid compliance, emoji audit, and compilation checks.
set -euo pipefail

here=${0:A:h}
root=${here:h}

echo "=== 1. Apple HIG 4pt/8pt Grid Lint ==="
"$here/grid-lint.sh"

echo ""
echo "=== 2. SwiftData In-App Self-Test ==="
"$here/selftest.sh"

echo ""
echo "=== 3. Zero Emojis Audit ==="
python3 -c "
import os, sys, unicodedata
folder = '$root/Sources'
violations = []
for r, d, files in os.walk(folder):
    for f in files:
        if f.endswith('.swift'):
            p = os.path.join(r, f)
            with open(p, 'r', encoding='utf-8', errors='ignore') as fp:
                for lno, line in enumerate(fp, 1):
                    for ch in line:
                        code = ord(ch)
                        if (0x1F300 <= code <= 0x1F9FF) or (0x2600 <= code <= 0x27BF and code != 0x2713):
                            violations.append((os.path.relpath(p, folder), lno, ch))
if violations:
    print(f'FAIL: Found {len(violations)} emoji violations!')
    for rel, lno, ch in violations[:10]:
        print(f'  {rel}:{lno} [{ch}]')
    sys.exit(1)
print('PASS Zero Emojis (100% System Glyphs)')
"

echo ""
echo "=== 4. Swift Release Compilation & Warnings Audit ==="
scratch="$HOME/Library/Developer/Kite/build"
swift build -c release --package-path "$root" --scratch-path "$scratch" 2>&1 | grep -i "warning:" && {
    echo "FAIL: Compiler warnings detected!"
    exit 1
} || echo "PASS 0 compiler warnings"

echo ""
echo "ALL QUALITY GATES PASSED (BAMA Craftsmanship Standard Verified)"
