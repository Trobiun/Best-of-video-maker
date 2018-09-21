#!/bin/bash
set -o errexit
set -o nounset

#CONFIG_FILE="config.cfg"
DEFAULT_CONFIG="defaultConfig.cfg"

#INPUT_DIR_NAME="input"
#TEMP_DIR_NAME="temp"
#OUTPUT_DIR_NAME="output"


generate_project() {
	project_name=$1
	mkdir -p "${project_name}"
	mkdir -p "${project_name}/${INPUT_DIR_NAME}"
	mkdir -p "${project_name}/${OUTPUT_DIR_NAME}"
	mkdir -p "${project_name}/${TEMP_DIR_NAME}"
	project_config="${project_name}/${CONFIG_FILE}"
	if [ ! -s "${project_config}" ]
	then
		cp "${DEFAULT_CONFIG}" "${project_config}"
		echo "export project_name=\"${project_name}\"" >> "${project_config}"
	fi
}

add_input() {
	input=$1
	cp "${input}" "${project_name}/${INPUT_DIR_NAME}"
	mkdir "${project_name}/${INPUT_DIR_NAME}/${CUTS_DIR_NAME}_lists"
}

add_filter() {
	#project_name=$1
	filter_file=$1
	basename=$(basename "${filter_file}")
	mkdir "${project_name}/${INPUT_DIR_NAME}/filters"
	cp "${filter_file}" "${project_name}/${INPUT_DIR_NAME}/${basename}"
	echo "filter_clips=${filter_file}" >> "${project_config}"
}

clean() {
	#project_name=$1
	nb_temp_files=$(wc --lines <<< "$(ls -l ${project_name}/${TEMP_DIR_NAME}/)" )
	if [ "${nb_temp_files}" -ge 2 ]
	then
		rm -r ./"${project_name}"/"${TEMP_DIR_NAME}"/*
	fi
}

mrproper() {
	#project_name=$1
	clean "${project_name}"
	output="${project_name}/${OUTPUT_DIR_NAME}/${project_name}.${FFMPEG_EXT}"
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
	project_config="./${project_name}/${CONFIG_FILE}"
	if [ -s "${project_config}"  ]
	then
		source "${project_config}"
	fi
	case "${command}" in
	"generate_project")
		generate_project "${project_name}" ;;
	"add_input")
		add_input "$other_args" ;;
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
