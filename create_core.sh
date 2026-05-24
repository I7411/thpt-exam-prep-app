#!/bin/bash

# Create directory structure
cd "$(dirname "$0")/lib" 2>/dev/null || cd lib

mkdir -p core/theme
mkdir -p core/constants
mkdir -p core/config
mkdir -p core/routes
mkdir -p core/utils
mkdir -p data/models
mkdir -p data/mock
mkdir -p data/local
mkdir -p data/remote
mkdir -p data/repositories
mkdir -p providers
mkdir -p screens/{splash,auth,student,document,exam,progress,notification,profile,teacher,admin}
mkdir -p widgets

echo "✓ Directories created"
echo "Now run: flutter clean && flutter pub get && flutter analyze"
