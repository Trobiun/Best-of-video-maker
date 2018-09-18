#!/bin/bash
set -o errexit
set -o nounset


#FFMPEG_ARGS="-movflags faststart"
#FFMPEG_CODEC_OPTIONS="-c:v copy -c:a copy"
#FFMPEG_EXT=mp4
##60 FPS : -framerate 60 -r 60
#FINAL_CLIPS_LIST_FILE="clips.txt"


ffmpeg_bin=$(./selectFFmpeg.sh "static")

#if [ $# -ge 3 ]
#then
    #project_name=$1
    #input_dir=$2
    #output_dir=$3
    input="${project_name}/${INPUT_DIR_NAME}/${FINAL_CLIPS_LIST_FILE}"
    output="${project_name}/${OUTPUT_DIR_NAME}/${project_name}.${FFMPEG_EXT}"
    "${ffmpeg_bin}" -f concat -safe 0 -i "${input}" ${FFMPEG_ARGS} ${FFMPEG_CODEC_OPTIONS} "${output}"
#fi
