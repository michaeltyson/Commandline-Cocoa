#!/bin/sh
# runcocoa.sh - Run any Cocoa code from the command line
# 
# Michael Tyson, A Tasty Pixel <michael@atastypixel.com>
#
ccflags="";
includes="";
usegdb=;
ios=;
includemain=yes;
while [ "${1:0:1}" = "-" ]; do
    if [ "$1" = "-include" ]; then
        shift;
        includes="$includes
#import <$1>";
    elif [ "$1" = "-gdb" ]; then
        usegdb=yes;
    elif [ "$1" = "-ios" ]; then
        ios=yes;
    elif [ "$1" = "-nomain" ]; then
        includemain=;
    else
        ccflags="$ccflags $1 $2";
        shift;
    fi;
    shift;
done;

commands=$*
if [ ! "$commands" ]; then
    commands="`cat`"
fi

if [ "$ios" ]; then
    includes="$includes
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>"
else
    includes="$includes
#import <Cocoa/Cocoa.h>";
fi

if [ "$includemain" ]; then
cat > /tmp/runcocoa.m << EOF
$includes
int main (int argc, const char * argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  $commands;
  [pool drain];
  return 0;
}
EOF
else
cat > /tmp/runcocoa.m << EOF
$includes
$commands;
EOF
fi

if [ "$ios" ]; then
    export MACOSX_DEPLOYMENT_TARGET=10.6
    export PATH="/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin:/Developer/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    gcc="/usr/bin/env llvm-gcc \
                -x objective-c -arch i386 -fmessage-length=0 -pipe -std=c99 -fpascal-strings -O0 \
                -isysroot /Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk -fexceptions -fasm-blocks \
                -mmacosx-version-min=10.6 -gdwarf-2 -fvisibility=hidden -fobjc-abi-version=2 -fobjc-legacy-dispatch -D__IPHONE_OS_VERSION_MIN_REQUIRED=40000 \
                -Xlinker -objc_abi_version -Xlinker 2 -framework Foundation -framework UIKit -framework CoreGraphics -framework CoreText";
else
    gcc="/usr/bin/env gcc -O0 -framework Foundation -framework Cocoa";
fi

if ! $gcc /tmp/runcocoa.m $ccflags -o /tmp/runcocoa-output; then
    exit 1;
fi

if [ "$ios" ]; then
    DYLD_ROOT_PATH="/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk" /tmp/runcocoa-output
elif [ "$usegdb" ]; then
    echo 'run; bt;' > /tmp/runcocoa-gdb
    gdb -x /tmp/runcocoa-gdb -e /tmp/runcocoa-output
    rm /tmp/runcocoa-gdb
else
    /tmp/runcocoa-output
fi
rm /tmp/runcocoa-output /tmp/runcocoa.m 2>/dev/null
