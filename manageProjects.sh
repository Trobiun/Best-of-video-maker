#!/bin/bash
set -o errexit
set -o nounset

CONFIG_FILE="config.cfg"

INPUT_DIR_NAME="input"
TEMP_DIR_NAME="temp"
OUTPUT_DIR_NAME="output"


generate_project() {
	project_name=$1
	mkdir "${project_name}"
	cd "${project_name}"
	mkdir "${INPUT_DIR_NAME}"
	mkdir "${OUTPUT_DIR_NAME}"
	mkdir "${TEMP_DIR_NAME}"
	project_config="${project_name}/${CONFIG_FILE}"
	if [ ! -s "${project_config}" ]
    then
        cp "${CONFIG_FILE}" "${project_config}"
        echo "export project_name=\"${project_name}\"" >> "${project_config}"
	fi
}

extract_cuts() {
	project_name=$1
	./extractCuts.sh #"${project_name}" "${INPUT_DIR_NAME}" "${TEMP_DIR_NAME}"
}

extract_clips() {
	project_name=$1
	./extractClips.sh #"${project_name}" "${INPUT_DIR_NAME}" "${TEMP_DIR_NAME}"
}

insertTransition() {
    project_name=$1
    ./insertTransition.sh #"${project_name}" "${INPUT_DIR_NAME}"
}

concat() {
    project_name=$1
    ./concat.sh #"${project_name}" "${INPUT_DIR_NAME}" "${OUTPUT_DIR_NAME}"
}

clean() {
    project_name=$1
    rm -r ./"${project_name}"/"${TEMP_DIR_NAME}"/*
}

mrproper() {
    project_name=$1
    clean "${project_name}"
    rm "${project_name}/${OUTPUT_DIR_NAME}/${project_name}.${FFMPEG_EXT}"
}

execute_command() {
	command=$1
	projet_name=$2
	source "./${project_name}/${CONFIG_FILE}"
	case "${command}" in
	"generate_project")
		generate_project "${project_name}" ;;
	"extract_cuts")
		extract_cuts "${project_name}" ;;
	"extract_clips")
		extract_clips "${project_name}" ;;
    "insert_transition")
        insertTransition "${project_name}" ;;
	"concat")
		concat "${project_name}" ;;
    "clean")
        clean "${project_name}" ;;
    "mrproper")
        mrproper "${project_name}" ;;
	esac
}

if [ $# -ge 2 ]
then
	command=$1
	project_name=$2
	execute_command "${command}" "${project_name}"
fi


