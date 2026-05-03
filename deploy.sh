#!/bin/bash

# Deploy script for hdhr_VCR
# Compiles applescript files and deploys to source location

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_DIR="$HOME/source/HDHR_VCR"
DOCS_DIR="$HOME/Documents"

echo "Killing running app..."
pkill -f "hdhr_VCR.app" || true
sleep 1

echo "Compiling main app..."
echo "  Source:      $REPO_DIR/hdhr_VCR.applescript"
echo "  Destination: $DEPLOY_DIR/hdhr_VCR.app"
osacompile -o "$DEPLOY_DIR/hdhr_VCR.app" "$REPO_DIR/hdhr_VCR.applescript"

# Set stay-open flag in app bundle Info.plist
PLIST="$DEPLOY_DIR/hdhr_VCR.app/Contents/Info.plist"
if [ -f "$PLIST" ]; then
	/usr/libexec/PlistBuddy -c "Add :LSStayOpen bool true" "$PLIST" 2>/dev/null || \
	/usr/libexec/PlistBuddy -c "Set :LSStayOpen true" "$PLIST"
fi

echo "Compiling library script..."
echo "  Source:      $REPO_DIR/hdhr_VCR_lib.applescript"
echo "  Destination: $DOCS_DIR/hdhr_VCR_lib.scpt"
osacompile -o "$DOCS_DIR/hdhr_VCR_lib.scpt" "$REPO_DIR/hdhr_VCR_lib.applescript"

echo "Deployed successfully"
