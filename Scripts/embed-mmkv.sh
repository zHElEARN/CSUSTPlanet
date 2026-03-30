#!/bin/sh
set -e

FRAMEWORK_NAME="MMKVAppExtension.framework"

PATH_DEBUG="$BUILT_PRODUCTS_DIR/PackageFrameworks/$FRAMEWORK_NAME"
PATH_ARCHIVE="$BUILT_PRODUCTS_DIR/$FRAMEWORK_NAME"

if [ -d "$PATH_ARCHIVE" ]; then
    SOURCE_PATH="$PATH_ARCHIVE"
elif [ -d "$PATH_DEBUG" ]; then
    SOURCE_PATH="$PATH_DEBUG"
else
    echo "error: Cannot find $FRAMEWORK_NAME in build directories."
    exit 1
fi

echo "Source found at: $SOURCE_PATH"

DEST_DIR="$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH"
mkdir -p "$DEST_DIR"

echo "Ditto copying to: $DEST_DIR/$FRAMEWORK_NAME"
ditto "$SOURCE_PATH" "$DEST_DIR/$FRAMEWORK_NAME"

if [ -n "$EXPANDED_CODE_SIGN_IDENTITY" ]; then
    echo "Signing $FRAMEWORK_NAME with identity: $EXPANDED_CODE_SIGN_IDENTITY"
    codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --preserve-metadata=identifier,entitlements "$DEST_DIR/$FRAMEWORK_NAME"
fi

echo "Successfully embedded and signed $FRAMEWORK_NAME"
