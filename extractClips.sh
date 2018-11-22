#!/bin/bash
set -o errexit
set -o nounset


ffmpeg_bin=$(./selectFFmpeg.sh "stable")


generate_filter_complex_args() {
	list_clips_file=$1
	nb_split=$2
	filter_stream=$3
	filter=$4
	filter_arg_function=$5
	filter_complex_args="'[0:${filter_stream}]split=${nb_split}"
	nb_in=1
	while IFS= read -r 'line' || [[ -n "${line}" ]]
	do
		filter_complex_args+="[in${filter_stream}${nb_in}]"
		nb_in=$((nb_in + 1))
	done < "${list_clips_file}"
	filter_complex_args+='\;'
	nb_in=1
	while IFS= read -r 'line' || [[ -n "${line}" ]]
	do
		effective_filter=$(())
		filter_complex_args+="[in${filter_stream}${nb_in}]${filter}[out${filter_stream}${nb_in}]"
		if  [ $nb_in -eq $((nb_split - 1)) ]
		then
			filter_complex_args+='\;'
		fi
		nb_in=$((nb_in + 1))
	done < "${list_clips_file}"
	filter_complex_args+="'"
	#printf "%s\n" "${filter_complex_args}"
	echo "${filter_complex_args}"
}


multiple_extract() {
	input=$1
	input_extension="${input##*.}"
	output_dir=$2
	list_clips_file=$3
	counter=$4
	if [ -d "${output_dir}" ]
	then
		#filter_complex_audio="'[0:a]split=${nb_split}"
		nb_split=$(wc --lines < "${list_clips_file}")
		i=1
		#while IFS= read -r 'line' || [[ -n "${line}" ]]
		#do
		#	filter_complex_audio+="[ina${1}]copy[outa${i}]"
		#	i=$((i + 1))
		#done < "${list_clips_file}"
		#filter_complex_audio+=';'
		
		#filter_complex_audio=$(generate_filter_complex_args "${list_clips_file}" "${nb_split}" "a" "copy" "increment_counter")
		
		#filter_complex_video=$()
		extract_cmd="\"${ffmpeg_bin}\" -fflags +genpts -i \"${input}\" -filter_complex " #-filter_complex '${filter_complex_audio}'
		filter_complex="'[0:v]split=${nb_split}"
		i=1
		while IFS= read -r 'line' || [[ -n "${line}" ]]
		do
			filter_complex+="[in${i}]"
			i=$((i + 1))
		done < "${list_clips_file}"
		filter_complex+=';'
		i=1
		while IFS= read -r 'line' || [[ -n "${line}" ]]
		do
			filter_complex+="[in${i}]"
			filter_complex+="drawtext=text=${counter}:x=0:y=0:fontcolor=white:fontsize=38"
			filter_complex+="[out${i}]"
			if  [ $i -eq $((nb_split - 1)) ]
			then
				filter_complex+=";"
			fi
			i=$((i + 1))
			counter=$((counter + 1))
		done < "${list_clips_file}"
		filter_complex+="'"
		i=1
		extract_cmd+=${filter_complex}
		while IFS= read -r 'line' || [[ -n "${line}" ]]
		do
			number=$(cut -f1 <<< "${line}")
			start=$(cut -f2 <<< "${line}")
			to=$(cut -f3 <<< "${line}")
			output_clip="${output_dir}/${number}.${FFMPEG_EXT}"
			if [ "${start}" = "00:00:00" ]
			then
				extract_cmd+=" -map '[out${i}]' -to ${to} ${FFMPEG_CODEC_OPTIONS} ${FFMPEG_ARGS} \"${output_clip}\" "
			else
				extract_cmd+=" -map '[out${i}]' -ss ${start} -to ${to} ${FFMPEG_CODEC_OPTIONS} ${FFMPEG_ARGS} \"${output_clip}\" "
			fi
			i=$((i + 1))
		done < "${list_clips_file}"
		extract_cmd+=" < /dev/null"
		eval "${extract_cmd}"
	fi
	echo "${counter}"
}

#pas fonctionnelle
multiple_extract_with_filter() {
	input=$1
	output_dir=$2
	list_clips_file=$3
	if [ -d "${output_dir}" ]
	then
		while IFS= read -r 'line' || [[ -n "${line}" ]]
		do
			number=$(cut -f1 <<< "${line}")
			start=$(cut -f2 <<< "${line}")
			end=$(cut -f3 <<< "${line}")
			duration=$(./diffTime.sh "${start}" "${end}")
			output_clip="${output_dir}/${number}.${FFMPEG_EXT}"
			args_pipe="-f matroska pipe:1"
			args_filter="${args} ${FFMPEG_UNCOMPRESSED_CODEC_OPTIONS} ${args_pipe}"
			"${ffmpeg_bin}" -i "${input}" -loglevel ${FFMPEG_LOG_LEVEL} ${args_filter} < /dev/null |  "./multipleExtractFilter.sh" "${input}" "${output_clip}" #"./${filter_clips}" "${output_clip}"
		done
	fi
}


extract_with_filter() {
	input=$1
	output_dir=$2
	list_clips_file=$3
	if [ -d "${output_dir}" ]
	then
		while IFS= read -r 'line' || [[ -n "${line}" ]]
		do
			number=$(cut -f1 <<< "${line}")
			start=$(cut -f2 <<< "${line}")
			end=$(cut -f3 <<< "${line}")
			duration=$(./diffTime.sh "${start}" "${end}")
			output_clip="${output_dir}/${number}.${FFMPEG_EXT}"
			args="${FFMPEG_TEMP_ARGS}"
			args_pipe="-f matroska pipe:1"
			args_filter="${args} ${FFMPEG_UNCOMPRESSED_CODEC_OPTIONS} ${args_pipe}"
			args_no_filter="${args} ${FFMPEG_TEMP_CODEC_OPTIONS}"
			ss=""
			tot=""
			if [ "${start}" != "00:00:00" -a "${start}" != "00:00:00.000" ]
			then
				ss="-ss ${start}"
				tot="-to ${end}"
				#tot="-t ${duration}"
			else
				tot="-to ${end}"
			fi
			#args="${tot} ${}"
			if [ -n ${filter_clips+x} ]
			then
				"${ffmpeg_bin}" -i "${input}" ${ss} ${tot} -loglevel ${FFMPEG_LOG_LEVEL} ${args_filter} < /dev/null | "./${PROJECTS_DIR}/${project_name}/${INPUT_DIR_NAME}/${filter_clips}" "${output_clip}"
			else
				"${ffmpeg_bin}" -i "${input}" ${ss} ${tot} -loglevel ${FFMPEG_LOG_LEVEL}   ${args_no_filter} "${output_clip}" < /dev/null
			fi
		done < "${list_clips_file}"
	fi
}


final_clips_list_file="${PROJECTS_DIR}/${project_name}/${INPUT_DIR_NAME}/${FINAL_CLIPS_LIST_FILE}"
rm -f "${final_clips_list_file}"
while IFS= read -r 'video'
do
	filebasename="$(basename "${video}")"
	filename="${filebasename%.*}"
	filename_escaped=$(sed -e 's/-/_/' <<< "${filename}")
	extension="${filebasename##*.}"
	dir_cuts="${PROJECTS_DIR}/${project_name}/${TEMP_DIR_NAME}/${CUTS_DIR_NAME}"
	dir_cuts_filename="${dir_cuts}/${filename}"
	dir_clips="${PROJECTS_DIR}/${project_name}/${TEMP_DIR_NAME}/${CLIPS_DIR_NAME}"
	dir_clips_filename="${dir_clips}/${filename}"
	mkdir -p "${dir_clips_filename}"
	while IFS= read -r 'list_file'
	do
		clips_basename=$(basename "${list_file}")
		clips_filename="${clips_basename%.*}"
		type_extract=$(cut -d'-' -f2 <<< "${clips_filename}" | sed -e 's/^[[:space:]]//g;s/[[:space:]]$//g')
		number=$(cut -d'-' -f3 <<< "${clips_filename}" | sed -e 's/^[[:space:]]//g')
		#type_extract_dir="${dir}/${type_extract}"
		cut_dir="${dir_cuts_filename}/${type_extract}" #"${type_extract_dir}" #/${CUTS_DIR_NAME}
		clips_dir="${dir_clips_filename}/${type_extract}/${number}" #"${type_extract_dir}/${number}" #/${CLIPS_DIR_NAME}
		mkdir -p "${clips_dir}"
		cut_video=$(find "${cut_dir}" -name "${filename_escaped} - ${type_extract} - ${number}.*")
		extract_with_filter "${cut_video}" "${clips_dir}" "${list_file}"
		while IFS= read -r 'line' || [[ -n "${line}" ]]
		do
			number_clip=$(cut -f1 <<< "${line}")
			echo "file '../../../${clips_dir}/${number_clip}.${FFMPEG_EXT}'" >>  "${final_clips_list_file}"
		done < "${list_file}"
	done < <(find "${PROJECTS_DIR}/${project_name}/${INPUT_DIR_NAME}/${CLIPS_LIST_DIR_NAME}" -type f -name "${filename_escaped}*.clips" -print | sort -n)
done < <(find "${PROJECTS_DIR}/${project_name}/${INPUT_DIR_NAME}" -maxdepth 1 -type f -exec file -N --mime-type -- {} + | sed -n 's!: video/[^:]*$!!p')
