#!/bin/bash
# Full regression suite, headless. Usage: bash tools/run_all_tests.sh
cd "$(dirname "$0")/.."
OUT=${OUT:-/tmp/claude-501/regress}
mkdir -p "$OUT"
G="godot --headless --path . --max-fps 0 --fixed-fps 60"
godot --headless --path . --import > "$OUT/import.log" 2>&1
$G res://tools/CheckScripts.tscn > "$OUT/check.log" 2>&1
$G res://tools/SmokeTest.tscn    > "$OUT/smoke.log" 2>&1
$G res://tools/SystemsTest.tscn  > "$OUT/systems.log" 2>&1
$G res://tools/CombatTest.tscn -- --runs 5 > "$OUT/combat.log" 2>&1
$G res://tools/QATest.tscn       > "$OUT/qa.log" 2>&1
$G res://tools/Playthrough.tscn  > "$OUT/play.log" 2>&1
$G res://tools/FlowTest.tscn     > "$OUT/flow.log" 2>&1
echo "===== REGRESSION SUMMARY ====="
echo "check:    $(grep -h 'CHECKED' $OUT/check.log)  script errors: $(grep -c 'SCRIPT ERROR' $OUT/check.log)"
echo "smoke:    script errors: $(grep -c 'SCRIPT ERROR' $OUT/smoke.log)  scenarios: $(grep -c '=== SCENARIO' $OUT/smoke.log)"
echo "systems:  $(grep -h 'SYSTEMS TEST DONE' $OUT/systems.log)  script errors: $(grep -c 'SCRIPT ERROR' $OUT/systems.log)"
echo "combat:   $(grep -h 'COMBAT TEST DONE' $OUT/combat.log)  script errors: $(grep -c 'SCRIPT ERROR' $OUT/combat.log)"
echo "qa:       $(grep -h 'QA TEST DONE' $OUT/qa.log)  script errors: $(grep -c 'SCRIPT ERROR' $OUT/qa.log)"
echo "play:     $(grep -h 'PLAYTHROUGH DONE' $OUT/play.log)  script errors: $(grep -c 'SCRIPT ERROR' $OUT/play.log)"
echo "flow:     $(grep -h 'FLOW TEST DONE' $OUT/flow.log)  script errors: $(grep -c 'SCRIPT ERROR' $OUT/flow.log)"
for f in $OUT/*.log; do grep -h -E "^\s*\[FAIL\]|^\[FAIL" "$f" | sed "s|^|$(basename $f): |" | head -5; done
