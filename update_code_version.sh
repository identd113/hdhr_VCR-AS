#!/bin/bash
# Helper script to update Code_version_epoch in hdhr_VCR.applescript
# This should be run before deploying to track code changes

SCRIPT_FILE="$1"
if [ -z "$SCRIPT_FILE" ]; then
	SCRIPT_FILE="$(cd "$(dirname "$0")" && pwd)/hdhr_VCR.applescript"
fi

# Get current epoch time
EPOCH=$(date +%s)

# Get current date in readable format
DATE_READABLE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

# Update the line in the script
sed -i '' "s/set Code_version_epoch to [0-9]* -- Updated: .*/set Code_version_epoch to $EPOCH -- Updated: $DATE_READABLE/" "$SCRIPT_FILE"

echo "✓ Updated Code_version_epoch to $EPOCH ($DATE_READABLE)"
echo "  File: $SCRIPT_FILE"
echo ""
echo "Now run: git add -A && git commit -m 'Update code version epoch' && bash deploy.sh"
