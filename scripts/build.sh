#!/bin/bash
# LastOne ビルド検証
#
# 注意: xcodebuild は CoreSimulator への XPC 接続を必ず行うため、
# Claude Code のサンドボックス内では必ず失敗する（既知の環境制約）。
# エージェントはこのスクリプトを dangerouslyDisableSandbox: true で実行すること。
set -o pipefail
cd "$(dirname "$0")/.."
LOG=build/last-build.log
mkdir -p build
xcodebuild \
  -project LastOne.xcodeproj \
  -scheme LastOne \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build/dd \
  "${@:-build}" > "$LOG" 2>&1
STATUS=$?
grep -E "error:|BUILD (SUCCEEDED|FAILED)" "$LOG" | sort -u | tail -40
echo "(full log: $LOG)"
exit $STATUS
