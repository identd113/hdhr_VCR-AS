#!/bin/bash

# Dump HDHomeRun guide and lineup data to JSON files
# Uses the same APIs as hdhr_VCR.applescript
# Output files can be parsed for analysis

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${1:-$SCRIPT_DIR/data}"
DEVICE_IP="${2:-hdhr-105404be.local}"
GUIDE_HOURS="${3:-6}"

echo "=== HDHomeRun Guide & Lineup Dumper ==="
echo "Output directory: $OUTPUT_DIR"
echo "Device IP: $DEVICE_IP"
echo "Guide hours: $GUIDE_HOURS"
echo ""

# Step 1: Discover device
echo "[1/3] Discovering device..."
DISCOVER_URL="http://$DEVICE_IP/discover.json"
DISCOVER_JSON=$(curl -s "$DISCOVER_URL")

if [ -z "$DISCOVER_JSON" ]; then
  echo "ERROR: Failed to fetch device discovery from $DISCOVER_URL"
  exit 1
fi

echo "$DISCOVER_JSON" > "$OUTPUT_DIR/discover.json"
echo "✓ Saved discovery to discover.json"

# Extract values from discovery
DEVICE_AUTH=$(echo "$DISCOVER_JSON" | jq -r '.DeviceAuth')
LINEUP_URL=$(echo "$DISCOVER_JSON" | jq -r '.LineupURL')
DEVICE_ID=$(echo "$DISCOVER_JSON" | jq -r '.DeviceID')

echo "  Device ID: $DEVICE_ID"
echo "  Device Auth: $DEVICE_AUTH"
echo "  Lineup URL: $LINEUP_URL"
echo ""

# Step 2: Fetch lineup
echo "[2/3] Fetching lineup..."
LINEUP_JSON=$(curl -s "$LINEUP_URL")

if [ -z "$LINEUP_JSON" ]; then
  echo "ERROR: Failed to fetch lineup from $LINEUP_URL"
  exit 1
fi

echo "$LINEUP_JSON" > "$OUTPUT_DIR/lineup.json"
LINEUP_COUNT=$(echo "$LINEUP_JSON" | jq 'length')
echo "✓ Saved lineup to lineup.json ($LINEUP_COUNT channels)"
echo ""

# Step 3: Fetch guide
echo "[3/3] Fetching guide..."
GUIDE_URL="https://api.hdhomerun.com/api/guide.php?DeviceAuth=$DEVICE_AUTH&Duration=$GUIDE_HOURS"
GUIDE_JSON=$(curl -s "$GUIDE_URL")

if [ -z "$GUIDE_JSON" ]; then
  echo "ERROR: Failed to fetch guide from $GUIDE_URL"
  exit 1
fi

echo "$GUIDE_JSON" > "$OUTPUT_DIR/guide.json"
GUIDE_COUNT=$(echo "$GUIDE_JSON" | jq 'length')
echo "✓ Saved guide to guide.json ($GUIDE_COUNT channels)"
echo ""

echo "=== Summary ==="
echo "Files created in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"/discover.json "$OUTPUT_DIR"/lineup.json "$OUTPUT_DIR"/guide.json 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo "To parse guide data, use jq:"
echo "  jq '.[] | {GuideNumber, Guide: [.Guide[0:3]]}' guide.json"
echo ""
echo "To find Rifleman episodes:"
echo "  jq '.[] | .Guide[] | select(.seriesID | contains(\"C510365\")) | {Title, GuideNumber, StartTime}' guide.json"
