#!/bin/bash

# Deploy script for hdhr_VCR
# Compiles AppleScript files and copies to source folder for distribution

set -e

SOURCE_REPO="/Users/plexserver/Documents/GitHub/hdhr_VCR"
DEPLOY_LOCATION="/Users/plexserver/source/HDHR_VCR"

echo "=== hdhr_VCR Deploy Script ==="
echo ""
echo "Source: $SOURCE_REPO"
echo "Deploy: $DEPLOY_LOCATION"
echo ""

# Ensure deploy location exists
mkdir -p "$DEPLOY_LOCATION"

# Compile main script with stay open flag
echo "Compiling hdhr_VCR.applescript..."
osacompile -x \
  -s \
  -o "$DEPLOY_LOCATION/hdhr_VCR.app" \
  "$SOURCE_REPO/hdhr_VCR.applescript"
echo "✓ Created hdhr_VCR.app"

# Copy text source files
echo "Copying source files..."
cp "$SOURCE_REPO/hdhr_VCR.applescript" "$DEPLOY_LOCATION/"
cp "$SOURCE_REPO/hdhr_VCR_lib.applescript" "$DEPLOY_LOCATION/"
echo "✓ Copied .applescript files"

# Create compiled script versions (.scpt)
echo "Creating .scpt files..."
osacompile -o "$DEPLOY_LOCATION/hdhr_VCR.scpt" "$SOURCE_REPO/hdhr_VCR.applescript"
osacompile -o "$DEPLOY_LOCATION/hdhr_VCR_lib.scpt" "$SOURCE_REPO/hdhr_VCR_lib.applescript"
echo "✓ Created .scpt files"

# Optional: Create a zip for distribution
echo "Creating distribution zip..."
cd "$DEPLOY_LOCATION"
zip -q -r hdhr_VCR_deploy.zip \
  hdhr_VCR.app \
  hdhr_VCR.applescript \
  hdhr_VCR.scpt \
  hdhr_VCR_lib.applescript \
  hdhr_VCR_lib.scpt \
  -x "*.DS_Store"
echo "✓ Created hdhr_VCR_deploy.zip"

echo ""
echo "=== Deploy Complete ==="
ls -lh "$DEPLOY_LOCATION"
