#!/bin/bash

# Deploy script for hdhr_VCR
# Compiles applescript files and deploys to source location

REPO_DIR="/Users/plexserver/Documents/GitHub/hdhr_VCR"
DEPLOY_DIR="/Users/plexserver/source/HDHR_VCR"
DOCS_DIR="/Users/plexserver/Documents"

echo "Killing running app..."
pkill -f "hdhr_VCR.app" || true
sleep 1

echo "Compiling main app..."
osacompile -o "$DEPLOY_DIR/hdhr_VCR.app" "$REPO_DIR/hdhr_VCR.applescript"

echo "Compiling library script..."
osacompile -o "$DEPLOY_DIR/hdhr_VCR_lib.scpt" "$REPO_DIR/hdhr_VCR_lib.applescript"

echo "Copying library to Documents folder..."
cp "$DEPLOY_DIR/hdhr_VCR_lib.scpt" "$DOCS_DIR/hdhr_VCR_lib.scpt"

echo "Deployed successfully"
