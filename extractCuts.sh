#!/bin/bash
set -o errexit
set -o nounset


ffmpeg_bin=$(./selectFFmpeg.sh "stable")

extract() {
	input=$1
	start=$2
	end=$3
	output=$4
	duration=$(./diffTime.sh "${start}" "${end}")
	if [ ! -s "${output}" ]
	then
		args="${FFMPEG_TEMP_CODEC_OPTIONS} ${FFMPEG_TEMP_ARGS}"
		ss=""
		tot=""
		if [ "${start}" != "00:00:00" -a "${start}" != "00:00:00.000" ]
		then
			ss="-ss ${start}"
			tot="-t ${duration}"
		else
			tot="-to ${end}"
		fi
		args="${tot} ${args}"
		"${ffmpeg_bin}" -loglevel ${FFMPEG_LOG_LEVEL} ${ss} -i "${input}" ${args} "${output}" < /dev/null
	fi
}


while IFS= read -r 'video'
do
	filebasename="$(basename "${video}")"
	filename="${filebasename%.*}"
	dir="${PROJECTS_DIR}/${project_name}/${TEMP_DIR_NAME}/${CUTS_DIR_NAME}/${filename}"
	mkdir -p "${dir}"
	while IFS= read -r 'list_file'
	do
		type_extracts="${list_file##*.}"
		type_extracts_dir="${dir}/${type_extracts}"
		mkdir -p "${type_extracts_dir}" #/${CUTS_DIR_NAME}
		while IFS= read -r 'line' || [[ -n "${line}" ]]
		do
			number=$(cut -f1 <<< "${line}")
			start=$(cut -f2 <<< "${line}")
			end=$(cut -f3 <<< "${line}")
			#duration=$(./diffTime.sh "${start}" "${end}")
			filename_escaped=$(sed -e 's/-/_/' <<< "${filename}")
			cut_filename="${filename_escaped} - ${type_extracts} - ${number}"
			cut_file="${cut_filename}.${FFMPEG_TEMP_EXT}"
			extract "${video}" "${start}" "${end}" "${type_extracts_dir}/${cut_file}" #/${CUTS_DIR_NAME}
			final_clips_lists="${PROJECTS_DIR}/${project_name}/${INPUT_DIR_NAME}/${CLIPS_LIST_DIR_NAME}/${cut_filename}.clips"
			if [ ! -f "${final_clips_lists}" ]
			then
				duration=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 -sexagesimal "${type_extracts_dir}/${cut_file}")
				mkdir -p "${PROJECTS_DIR}/${project_name}/${INPUT_DIR_NAME}/${CLIPS_LIST_DIR_NAME}"
				echo "01	00:00:00.000	${duration}" > "${final_clips_lists}"
			fi
		done < "${list_file}"
	done < <(find "${PROJECTS_DIR}/${project_name}" -type f -name "${filename}.*" -not -name "${filebasename}" -print)
done < <(find "${PROJECTS_DIR}/${project_name}/${INPUT_DIR_NAME}" -maxdepth 1 -type f -exec file -N --mime-type -- {} + | sed -n 's!: video/[^:]*$!!p')
