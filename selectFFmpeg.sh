#!/bin/bash
set -o errexit
set -o nounset

ffmpeg_4_0_2="/home/robin/bin/ffmpeg-4.0.2-64bit-static/"

ffmpeg_dir=$(dirname $(which ffmpeg))

if [ $# -ge 1 ]
then
	selection=$1
	if [ "${selection}" = "4.0.2_static" ]
	then
		ffmpeg_dir="${ffmpeg_4_0_2}"
	fi
fi

echo "${ffmpeg_dir}"
