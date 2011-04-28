#!/bin/sh
commands=$*
if [ ! "$commands" ]; then
    commands="`cat`"
fi
cat > /tmp/runc.c << EOF
#include <stdio.h>
#include <math.h>
int main(int argc, char** argv) {
  $commands;
}
EOF

if cc -o /tmp/runc-output -lm /tmp/runc.c; then
    /tmp/runc-output
fi
rm /tmp/runc-output /tmp/runc.c 2>/dev/null
