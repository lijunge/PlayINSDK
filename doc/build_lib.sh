#!/bin/bash

#target=$1
target=playin

xcodebuild clean -target $target

# Build Framework for iOS Simulator.
#xcodebuild build BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode" GCC_GENERATE_DEBUGGING_SYMBOLS=NO DEPLOYMENT_POSTPROCESSING=YES STRIP_INSTALLED_PRODUCT=YES STRIP_STYLE=non-global -target $target -configuration Release -sdk iphonesimulator -quiet

xcodebuild build -target $target -sdk iphonesimulator -quiet

# Build Framework for iOS Device.
#xcodebuild build BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode" GCC_GENERATE_DEBUGGING_SYMBOLS=NO DEPLOYMENT_POSTPROCESSING=YES STRIP_INSTALLED_PRODUCT=YES STRIP_STYLE=non-global -target $target -configuration Release -sdk iphoneos -quiet

xcodebuild build -target $target -sdk iphoneos -quiet

rm -rf *.a
lipo -create build/Release-iphoneos/lib$target.a build/Release-iphonesimulator/lib$target.a -output doc/libplayin/libplayin.a
cp playin/PlayIn.h doc/libplayin/
# strip doc/PlayInAir/libplayin/libplayin.lib

#cp PlayInAir/VideoViewController.m doc/PlayInAir/

rm -rf build
