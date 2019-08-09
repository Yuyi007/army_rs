sh "$PROJECT_DIR/../ios_build_run_script.sh"
rm -rf "$TARGET_BUILD_DIR/$PRODUCT_NAME.app/Data"
cp -LRf "$PROJECT_DIR/Data" "$TARGET_BUILD_DIR/$PRODUCT_NAME.app/Data"