#!/bin/bash
set -e

# hdhr_VCR Installer
# Downloads, compiles, and installs hdhr_VCR and its dependencies

REPO="https://raw.githubusercontent.com/m-woodfill/hdhr_VCR/main"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "📺 hdhr_VCR Installer"
echo "======================"
echo ""

# Check for macOS
if [[ ! "$OSTYPE" == "darwin"* ]]; then
    echo "❌ macOS required"
    exit 1
fi

echo "✓ macOS detected"
echo ""

# Check for osacompile
if ! command -v osacompile &> /dev/null; then
    echo "❌ osacompile not found. Please install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi
echo "✓ osacompile found"

# Install JSONHelper if needed
echo ""
echo "Checking JSONHelper..."
JSONHELPER_INSTALLED=false
if open -Ra JSONHelper &> /dev/null; then
    echo "✓ JSONHelper already installed"
    JSONHELPER_INSTALLED=true
else
    echo "JSONHelper not found."
    read -p "Install JSONHelper from App Store? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Opening App Store... Please click \"Get\" then \"Install\""
        open "macappstore://apps.apple.com/app/json-helper-for-applescript/id453114608"

        # Wait for installation
        echo "Waiting for JSONHelper installation..."
        for i in {1..60}; do
            if open -Ra JSONHelper &> /dev/null; then
                echo "✓ JSONHelper installed"
                JSONHELPER_INSTALLED=true
                break
            fi
            sleep 1
        done

        if [ "$JSONHELPER_INSTALLED" = false ]; then
            echo "⚠️  JSONHelper installation timed out. Please install manually:"
            echo "   https://apps.apple.com/us/app/json-helper-for-applescript/id453114608"
        fi
    else
        echo "⚠️  JSONHelper is required. Install it from:"
        echo "   https://apps.apple.com/us/app/json-helper-for-applescript/id453114608"
        exit 1
    fi
fi

echo ""
echo "Downloading scripts..."

# Download the scripts
if ! curl -fsSL "$REPO/hdhr_VCR.applescript" -o "$TEMP_DIR/hdhr_VCR.applescript"; then
    echo "❌ Failed to download hdhr_VCR.applescript"
    exit 1
fi
echo "✓ Downloaded hdhr_VCR.applescript"

if ! curl -fsSL "$REPO/hdhr_VCR_lib.applescript" -o "$TEMP_DIR/hdhr_VCR_lib.applescript"; then
    echo "❌ Failed to download hdhr_VCR_lib.applescript"
    exit 1
fi
echo "✓ Downloaded hdhr_VCR_lib.applescript"

echo ""
echo "Compiling..."

# Compile main app
echo "  Compiling main app..."
if ! osacompile -o "/Applications/hdhr_VCR.app" "$TEMP_DIR/hdhr_VCR.applescript"; then
    echo "❌ Failed to compile main app"
    exit 1
fi

# Set LSStayOpen flag
PLIST="/Applications/hdhr_VCR.app/Contents/Info.plist"
if [ -f "$PLIST" ]; then
    /usr/libexec/PlistBuddy -c "Add :LSStayOpen bool true" "$PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :LSStayOpen true" "$PLIST"
fi

echo "✓ Main app compiled: /Applications/hdhr_VCR.app"

# Compile library
echo "  Compiling library..."
if ! osacompile -o "$HOME/Documents/hdhr_VCR_lib.scpt" "$TEMP_DIR/hdhr_VCR_lib.applescript"; then
    echo "❌ Failed to compile library"
    exit 1
fi
echo "✓ Library compiled: ~/Documents/hdhr_VCR_lib.scpt"

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Launch hdhr_VCR: open /Applications/hdhr_VCR.app"
echo "  2. Grant macOS permissions when prompted"
echo "  3. Add your first show"
echo ""
