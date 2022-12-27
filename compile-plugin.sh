#!/bin/sh

wla-6502 -o temp.o $1
echo -e "[objects]\ntemp.o" > temp.link
wlalink temp.link "$(echo "$1" | cut -f 1 -d '.').bin"
rm temp.link
rm temp.o
