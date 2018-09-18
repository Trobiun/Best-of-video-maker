#!/bin/bash

#ffmpeg_bin=$(./selectFFmpeg.sh "stable")

counter=$1

FFMPEG_ARGS="-vf drawtext=text=\'${counter}\':x=0:y=0:fontcolor=white:fontsize=38"
FFMPEG_CODEC_OPTIONS="-codec:a copy -codec:v libx264 -b:v 4000k"


ffmpeg -i pipe:0 ${FFMPEG_ARGS} ${FFMPEG_CODEC_OPTIONS} -f mp4 TestLol.mp4
