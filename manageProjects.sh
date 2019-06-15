#!/bin/bash
set -o errexit
set -o nounset


DEFAULT_CONFIG="defaultConfig.cfg"
ffmpeg_dir=$(./selectFFmpeg.sh "stable")
ffprobe_bin="${ffmpeg_dir}/ffprobe"


generate_project() {
	project_name=$1
	mkdir -p "${PROJECTS_DIR}/${project_name}"
	mkdir -p "${PROJECTS_DIR}/${project_name}/${INPUT_DIR_NAME}"
	mkdir -p "${PROJECTS_DIR}/${project_name}/${OUTPUT_DIR_NAME}"
	mkdir -p "${PROJECTS_DIR}/${project_name}/${TEMP_DIR_NAME}"
	project_config="${PROJECTS_DIR}/${project_name}/${CONFIG_FILE}"
	if [ ! -s "${project_config}" ]
	then
		cp "${DEFAULT_CONFIG}" "${project_config}"
		echo "export project_name=\"${project_name}\"" >> "${project_config}"
		echo "export result_name=\"${project_name}\"" >> "${project_config}"
	fi
}

add_input() {
	input=$1
	cp "${input}" "${PROJECTS_DIR}/${project_name}/${INPUT_DIR_NAME}"
	cuts_lists_dir="${PROJECTS_DIR}/${project_name}/${INPUT_DIR_NAME}/${CUTS_DIR_NAME}_lists"
	mkdir -p "${cuts_lists_dir}"
	input_name=$(basename "${input}")
	duration=$("${ffprobe_bin}" -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 -sexagesimal "${PROJECTS_DIR}/${project_name}/${INPUT_DIR_NAME}/${input_name}")
	echo "01	00:00:00.000	${duration}" > "${cuts_lists_dir}/${input_name%.*}.list"
}

add_filter() {
	filter_file=$1
	basename=$(basename "${filter_file}")
	mkdir -p "${PROJECTS_DIR}/${project_name}/${INPUT_DIR_NAME}/${FILTERS_DIR_NAME}"
	cp "${filter_file}" "${PROJECTS_DIR}/${project_name}/${INPUT_DIR_NAME}/${FILTERS_DIR_NAME}/${basename}"
	echo "filter_clips=\"${filter_file}\"" >> "${project_config}"
}

clean() {
	nb_temp_files=$(wc --lines <<< $(ls -l "${PROJECTS_DIR}"/"${project_name}"/"${TEMP_DIR_NAME}"))
	#si le nombre de fichiers temporaires sont supérieurs à deux
	#cela veut dire qu'il y a des fichiers ou dossiers autres que "cuts" et "dir"
	if [ "${nb_temp_files}" -ge 2 ]
	then
		rm -r ./"${PROJECTS_DIR}"/"${project_name}"/"${TEMP_DIR_NAME}"/*
	fi
}

#A AMÉLIORER : changer de façon d'organiser les répertoires
#clean_cuts() {
#	cuts_dir="${project_name}/${TEMP_DIR_NAME}/${CUTS_DIR_NAME}"
#	nb_temp_files=$(wc --lines <<< "$(ls -l "${cuts_dir}")" )
#	if [ "${nb_temp_files}" -ge 2 ]
#	then
#		rm -r ./${cuts_dir} #./"${project_name}"/"${TEMP_DIR_NAME}"/${CUTS_DIR_NAME}
#	fi
#}

mrproper() {
	clean "${PROJECTS_DIR}/${project_name}"
	output="${PROJECTS_DIR}/${project_name}/${OUTPUT_DIR_NAME}/${project_name}.${FFMPEG_EXT}"
	if [ -e "${output}" ]
	then
		rm "${output}"
	fi
}

execute_command() {
	command=$1
	projet_name=$2
	other_args=$3
	source "${DEFAULT_CONFIG}"
	project_config="${PROJECTS_DIR}/${project_name}/${CONFIG_FILE}"
	if [ -s "${project_config}"  ]
	then
		source "${project_config}"
	fi
	case "${command}" in
	"generate_project")
		generate_project "${project_name}" ;;
	"add_input")
		add_input "${other_args}" ;;
	"add_filter")
		add_filter "${other_args}" ;;
	"extract_cuts")
		./extractCuts.sh ;;
	"extract_clips")
		./extractClips.sh ;;
	"insert_transition")
		./insertTransition.sh ;;
	"concat")
		./concat.sh ;;
	#"clean_cuts")
	#	clean_cuts ;;
	"clean")
		clean ;;
	"mrproper")
		mrproper ;;
	esac
	
}

if [ $# -ge 2 ]
then
	command=$1
	project_name=$2
	other_args="${@:3}"
	execute_command "${command}" "${project_name}" "${other_args}"
fi
