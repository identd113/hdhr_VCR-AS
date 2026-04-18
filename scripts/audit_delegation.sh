#!/bin/bash
# Audit library handler delegation in hdhr_VCR.applescript
# Usage: cd /Users/plexserver/Documents/GitHub/hdhr_VCR && bash scripts/audit_delegation.sh
SCRIPT="hdhr_VCR.applescript"
HANDLERS=(
  short_date stringlistflip ms2time epoch2datetime getTfromN date2touch
  seriesScanAdd seriesScanRun seriesScan seriesScanNext seriesScanUpdate
  seriesStatusIcons seriesScanRefresh seriesScanList
  update_folder HDHRShowSearch checkDiskSpace checkfileexists emptylist
  fixDate stringToUtf8 isSystemShutdown repeatProgress list_position
  padnum is_number end_jsonhelper epoch2show_time tuner_dump
  encode_strikethrough itemsInString check_after_midnight isModifierKeyPressed
  quoteme time_set midnight_of serialize_show deserialize_show corrupt_showinfo iconEnumPopulate aroundDate rotate_logs
  update_record_urls add_record_url match2showid recordSee show_name_fix
  convertByteSize cleanFolder curl2icon showSeek get_show_state2 nextday2
  enums2icons show_icons recordSee2 choose_folder_with_fallback choose_folder_with_fallback_v2
)

echo "=== Library Delegation Audit ==="
FOUND=0
for handler in "${HANDLERS[@]}"; do
  # Find calls, skip definitions (on handlerName) and lines already having of LibScript
  results=$(grep -n "${handler}(" "$SCRIPT" | grep -v "^\s*[0-9]*:.*\bon ${handler}(" | grep -v "of LibScript")
  if [ -n "$results" ]; then
    echo ""
    echo "POTENTIAL VIOLATION — $handler:"
    echo "$results"
    FOUND=1
  fi
done
if [ "$FOUND" -eq 0 ]; then
  echo "✓ No violations found."
fi
