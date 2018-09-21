#!/bin/bash
set -o errexit
set -o nounset


transition_video="${project_name}/${INPUT_DIR_NAME}/${INPUT_DIR_TRANSITION}/${TRANSITION_VIDEO_NAME}"
if [ -s "${transition_video}" ]
then
	final_list_clips_file="${project_name}/${INPUT_DIR_NAME}/${FINAL_CLIPS_LIST_FILE}"
	awk -i inplace -v line="file '../../${transition_video}'" '/^.*$/{ printf "%s\n%s\n", $0, line; next;}; 1' "${final_list_clips_file}"
fi
