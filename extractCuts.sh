#!/bin/bash
set -o errexit
set -o nounset

#CUTS_DIR_NAME="cuts"
#CLIPS_DIR_NAME="clips"
#
#CUTS_LIST_DIR_NAME="${CUTS_DIR_NAME}_lists"
#CLIPS_LIST_DIR_NAME="${CLIPS_DIR_NAME}_lists"
#
#FFMPEG_ARGS="-map_metadata -1 -avoid_negative_ts 1"
#FFMPEG_CODEC_OPTIONS="-c:v copy -c:a copy"
#FFMPEG_EXT=avi

ffmpeg_bin=$(./selectFFmpeg.sh "stable")

extract() {
	input=$1
	start=$2
	end=$3
	output=$4
	#duration=$(./diffTime.sh "${start}" "${end}")
	if [ ! -s "${output}" ]
	then
		if [ "${start}" = "00:00:00" ]
		then
			"${ffmpeg_bin}" -i "${input}" -to "${end}" ${FFMPEG_TEMP_CODEC_OPTIONS} ${FFMPEG_TEMP_ARGS} -f mp4 "${output}" </dev/null
		else
			"${ffmpeg_bin}" -i "${input}" -ss "${start}" -to "${end}" ${FFMPEG_TEMP_CODEC_OPTIONS} ${FFMPEG_TEMP_ARGS} -f mp4 "${output}" </dev/null
		fi
		
	fi
}

#if [ $# -ge 3 ]
#then
	#project_name=$1
	#input_dir_name=$2
	#temp_dir_name=$3
	while IFS= read -r 'video'
	do
		filebasename="$(basename "${video}")"
		filename="${filebasename%.*}"
		#extension="${filebasename##*.}"
		dir="${project_name}/${TEMP_DIR_NAME}/${filename}"
		mkdir -p "${dir}"
		while IFS= read -r 'list_file'
		do
			type_extracts="${list_file##*.}"
			type_extracts_dir="${dir}/${type_extracts}"
			mkdir -p "${type_extracts_dir}/${CUTS_DIR_NAME}"
			#mkdir -p "${type_extracts_dir}/${CLIPS_DIR_NAME}"
			while IFS= read -r 'line' || [[ -n "${line}" ]]
			do
				number=$(cut -f1 <<< "${line}")
				start=$(cut -f2 <<< "${line}")
				end=$(cut -f3 <<< "${line}")
				duration=$(./diffTime.sh "${start}" "${end}")
				#clips_dir="${filename} ${type_extracts} ${number}"
				#mkdir -p "${type_extracts_dir}/${CLIPS_DIR_NAME}/${clips_dir}"
				filename_escaped=$(sed -e 's/-/_/' <<< "${filename}")
				cut_filename="${filename_escaped} - ${type_extracts} - ${number}"
				cut_file="${cut_filename}.${FFMPEG_TEMP_EXT}"
				extract "${video}" "${start}" "${end}" "${type_extracts_dir}/${CUTS_DIR_NAME}/${cut_file}"
				final_clips_lists="${project_name}/${INPUT_DIR_NAME}/${CLIPS_LIST_DIR_NAME}/${cut_filename}.clips"
				#mkdir -p ""
				if [ ! -f "${final_clips_lists}" ]
				then
                    echo "01	00:00:00.000	${duration}.000" > "${final_clips_lists}"
                fi
			done < "${list_file}"
		done < <(find "${project_name}" -type f -name "${filename}.*" -not -name "${filebasename}" -print)
	done < <(find "${project_name}/${INPUT_DIR_NAME}" -maxdepth 1 -type f -exec file -N --mime-type -- {} + | sed -n 's!: video/[^:]*$!!p')
	#multiple_extract "input/Test1.mp4" "/shared/Scripts videos/test/temp/Test1/morts/cuts/Test1 morts 01" "/shared/Scripts videos/test/input/cuts_lists/Test1.lol"
#fi
