#!/bin/bash

set -euxo pipefail

MODULE_NAME=${1:?"Must set module name"}
PROJ_DIR="$(cd $(dirname $0) && pwd)"
WORKING_DIR="${PROJ_DIR}/${MODULE_NAME}"

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

echo "*** ${MODULE_NAME} build process finished ***"
