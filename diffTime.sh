#!/bin/bash

# Time Arithmetic
START=$1
END=$2

# Convert the times to seconds from the Epoch
SEC1=$(date +%s -d "${START}")
SEC2=$(date +%s -d "${END}")

# Use expr to do the math, let's say TIME1 was the start and TIME2 was the finish
DIFFSEC=$(("${SEC2}" - "${SEC1}"))

# And use date to convert the seconds back to something more meaningful
echo "$(date +%H:%M:%S -ud @"${DIFFSEC}")"
