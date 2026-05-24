#!/bin/bash

# Create all required directories for Flutter project structure
cd lib

# Core directories
mkdir -p core/config
mkdir -p core/constants
mkdir -p core/routes
mkdir -p core/theme
mkdir -p core/utils

# Data directories
mkdir -p data/models
mkdir -p data/mock
mkdir -p data/local
mkdir -p data/remote
mkdir -p data/repositories

# Other directories
mkdir -p providers

# Screens directories
mkdir -p screens/splash
mkdir -p screens/auth
mkdir -p screens/student
mkdir -p screens/document
mkdir -p screens/exam
mkdir -p screens/progress
mkdir -p screens/notification
mkdir -p screens/profile
mkdir -p screens/teacher
mkdir -p screens/admin

# Widgets directory
mkdir -p widgets

echo "✓ All directories created successfully!"
