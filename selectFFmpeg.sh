#!/bin/bash
set -o errexit
set -o nounset

STATIC_FFMPEG="/home/robin/ffmpeg-4.0.2-64bit-static/ffmpeg"

ffmpeg_bin=$(which ffmpeg)

if [ $# -ge 1 ]
then
	selection=$1
	if [ "${selection}" = "static" ]
	then
		ffmpeg_bin="${STATIC_FFMPEG}"
	fi
fi

echo "${ffmpeg_bin}"
