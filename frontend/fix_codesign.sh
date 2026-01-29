#!/bin/bash

# Fix iOS code signing issues for simulator builds
echo "Fixing iOS code signing configuration..."

# Clean the project
flutter clean

# Remove Pods and reinstall
cd ios
rm -rf Pods
rm -rf Podfile.lock
pod install

# Update Xcode project settings for simulator builds
# Remove development team requirement for simulator
sed -i '' 's/DEVELOPMENT_TEAM = 2D6SGWRP95;/DEVELOPMENT_TEAM = "";/g' Runner.xcodeproj/project.pbxproj

# Set code sign identity to empty for simulator
sed -i '' 's/"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = "iPhone Developer";/"CODE_SIGN_IDENTITY[sdk=iphonesimulator*]" = "";/g' Runner.xcodeproj/project.pbxproj

echo "Code signing configuration updated. Try building again."