#!/bin/bash

set -euxo pipefail

MODULE_NAME=${1:?"Must set module name"}
PROJ_DIR="$(cd $(dirname $0) && pwd)"
WORKING_DIR="${PROJ_DIR}/${MODULE_NAME}"
VERSIONS_PATH="${PROJ_DIR}/versions"

if [ ! -f "${VERSIONS_PATH}" ]; then
    echo "${VERSIONS_PATH} does not exist"
    exit 2
fi

MODULE_VERSION=$(grep "${MODULE_NAME} Version" "${VERSIONS_PATH}" | grep -oE '\d+.\d+.\d+')

if [ "${MODULE_VERSION}" = "" ]; then
    echo "${MODULE_NAME} version not found in ${VERSIONS_PATH}"
    exit 3
fi

VERSION_NUM=$(grep "Repository Version" "${VERSIONS_PATH}" | grep -oE '\d+.\d+.\d+')

if [ "${VERSION_NUM}" = "" ]; then
    echo "Repository version not found in ${VERSIONS_PATH}"
    exit 3
fi

PRODUCTS_DIR="${PROJ_DIR}/Products"
CART_DIR="${WORKING_DIR}/Carthage"
ZIP_PATH="${PRODUCTS_DIR}/${MODULE_NAME}.xcframework.zip"
TEMP_FRAMEWORK_PATH="${WORKING_DIR}/${MODULE_NAME}.xcframework.zip"

cd "${WORKING_DIR}"

carthage build --platform iOS --no-skip-current "${MODULE_NAME}" --use-xcframeworks
(cd $CART_DIR/Build; zip -r $TEMP_FRAMEWORK_PATH $MODULE_NAME.xcframework)

if [ ! -f "${TEMP_FRAMEWORK_PATH}" ]; then
    echo "${TEMP_FRAMEWORK_PATH} does not exist"
    exit 4
fi

if [ ! -d "${PRODUCTS_DIR}" ]; then
    mkdir "${PRODUCTS_DIR}"
fi

mv "${TEMP_FRAMEWORK_PATH}" "${ZIP_PATH}"

echo ""
echo "*** Removing Carthage directory ***"
rm -rf ${CART_DIR}

# Generate JSON file
JSON_PATH="${PROJ_DIR}/${MODULE_NAME}.json"
URL="https://github.com/abema/twitter-kit-ios/releases/download/${VERSION_NUM}/${MODULE_NAME}.zip"
TEMP_PATH="${WORKING_DIR}/temp.json"

echo ""
echo "*** Creating ${MODULE_NAME}.json ***"
echo ""

if [ -f "${TEMP_PATH}" ]; then
    rm -f "${TEMP_PATH}"
fi

if [ -s "${JSON_PATH}" ]; then
    if [ "$(grep "${MODULE_VERSION}" "${JSON_PATH}")" = "" ]; then
        # If version number does not exist, insert newline
        sed -e 's/"$/",/g' -e '/^}$/d' "${JSON_PATH}" > "${TEMP_PATH}"
        echo -e "\t\"${MODULE_VERSION}\": \"${URL}\"\n}" >> "${TEMP_PATH}"
    else
        # If version number exists, replace line
        REGEX="s|\"${MODULE_VERSION}\": \(.*\)|\"${MODULE_VERSION}\": \"${URL}\"|g"
        sed -e "${REGEX}" "${JSON_PATH}" > "${TEMP_PATH}"
    fi
    mv "${TEMP_PATH}" "${JSON_PATH}"
else
    # Create Json file if file does not exist or is empty
    echo -e "{\n\t\"${MODULE_VERSION}\": \"${URL}\"\n}" > "${JSON_PATH}"
fi

echo "*** ${MODULE_NAME} build process finished ***"
