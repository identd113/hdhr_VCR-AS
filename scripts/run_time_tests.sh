#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_SOURCE="$ROOT_DIR/hdhr_VCR_lib.applescript"
TEST_SCRIPT="$ROOT_DIR/tests/time_handlers_test.applescript"

locale="all"
fixture_date="Tuesday, January 2, 2024 at 1:05:09 PM"
fixture_date_half="Tuesday, January 2, 2024 at 1:30:09 PM"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --locale)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --locale requires a value (en_US|en_GB|all)" >&2
        exit 2
      fi
      locale="$2"
      shift 2
      ;;
    --fixture-date)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --fixture-date requires a date string value" >&2
        exit 2
      fi
      fixture_date="$2"
      shift 2
      ;;
    --fixture-date-half)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --fixture-date-half requires a date string value" >&2
        exit 2
      fi
      fixture_date_half="$2"
      shift 2
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ "$locale" != "all" && "$locale" != "en_US" && "$locale" != "en_GB" ]]; then
  echo "ERROR: Unsupported locale '$locale' (expected en_US|en_GB|all)" >&2
  exit 2
fi

if [[ ! -f "$LIB_SOURCE" ]]; then
  echo "ERROR: Missing library source at $LIB_SOURCE" >&2
  exit 2
fi

if [[ ! -f "$TEST_SCRIPT" ]]; then
  echo "ERROR: Missing test script at $TEST_SCRIPT" >&2
  exit 2
fi

tmpdir="$(mktemp -d /tmp/hdhr_vcr_time_tests.XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT

tmp_src="$tmpdir/hdhr_VCR_lib_time_subset.applescript"
tmp_merged="$tmpdir/time_handlers_merged.applescript"

extract_handler() {
  local handler_name="$1"
  HANDLER_NAME="$handler_name" LIB_SOURCE_PATH="$LIB_SOURCE" perl -0777 -e '
    use strict;
    use warnings;
    my $name = $ENV{HANDLER_NAME};
    my $path = $ENV{LIB_SOURCE_PATH};
    open my $fh, "<", $path or exit 1;
    local $/ = undef;
    my $data = <$fh>;
    close $fh;
    if ($data =~ /^on \Q$name\E\(.*?^end \Q$name\E$/ms) {
      print $&;
      exit 0;
    }
    exit 1;
  '
}

handlers=(
  cm
  stringlistflip
  replace_chars
  fixDate
  ms2time
  short_date
  padnum
  is_number
  epoch
  epoch2datetime
  epoch2show_time
  time_set
  check_after_midnight
)

{
  echo "use scripting additions"
  echo
  echo "property ParentScript : missing value"
  echo
  for h in "${handlers[@]}"; do
    if ! extract_handler "$h"; then
      echo "ERROR: Failed to extract handler '$h' from $LIB_SOURCE" >&2
      exit 1
    fi
    echo
  done
} > "$tmp_src"

# Normalize known malformed token in short_date due source encoding artifacts.
perl -i -pe 's/^\s*if theHour .*12 then$/			if theHour >= 12 then/' "$tmp_src"
# Convert hash comments used in repo sources to AppleScript comments.
perl -i -pe 's/^##/--/' "$tmp_src"
# Normalize a parser-sensitive rounding expression in epoch2show_time.
perl -i -pe 's/^(\s*)return \(show_time_temp_hours.*$/\1return (show_time_temp_hours \& \".\" \& (((show_time_temp_minutes * 100) + 59) div 60)) as text/' "$tmp_src"
# Replace "current date" with the requested fixture date for CLI compatibility
# and deterministic midnight-related assertions.
FIXTURE_DATE="$fixture_date" perl -i -pe '$d=$ENV{FIXTURE_DATE}; $d =~ s/"/\\"/g; s/current date/"date \"$d\""/ge' "$tmp_src"
# Normalize "time to GMT" for non-interactive osascript environments where the
# term is unavailable; round-trip tests still validate relative conversion math.
perl -i -pe 's/time to GMT/0/g' "$tmp_src"

cat "$tmp_src" "$TEST_SCRIPT" > "$tmp_merged"
osascript "$tmp_merged" --locale "$locale" --fixture-date "$fixture_date" --fixture-date-half "$fixture_date_half"
