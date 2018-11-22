#!/bin/bash
set -o errexit
set -o nounset

ffmpeg_bin=$(./selectFFmpeg.sh "static")

input="${PROJECTS_DIR}/${project_name}/${INPUT_DIR_NAME}/${FINAL_CLIPS_LIST_FILE}"
output="${PROJECTS_DIR}/${project_name}/${OUTPUT_DIR_NAME}/${result_name}.${FFMPEG_EXT}"

"${ffmpeg_bin}" -f concat -safe 0 -i "${input}" ${FFMPEG_ARGS} ${FFMPEG_OUTPUT_ARGS} ${FFMPEG_CODEC_OPTIONS} "${output}" < /dev/null
