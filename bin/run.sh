#!/bin/sh

KSFILE=$1

echo "Validating $KSFILE"
ksvalidator $KSFILE

echo "Creating livecd with $KSFILE"
exec livecd-creator --config=$KSFILE