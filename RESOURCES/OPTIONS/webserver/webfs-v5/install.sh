#!/bin/bash

# Install webfs-v5 (legacy webserver)
# Expects from parent script:
#   - OPTIONS_DIR
#   - package_name
#   - target_folder (or ROOTFS_DIR)
# Outputs:
#   - webserver_cfg_dst: path where webserver.json should be created

# Guard: check required variables
if [ -z "$OPTIONS_DIR" ]; then
  echo -e "${RED}ERROR: OPTIONS_DIR not set${NC}"
  exit 1
fi

if [ -z "$package_name" ]; then
  echo -e "${RED}ERROR: package_name not set${NC}"
  exit 1
fi

if [ -z "$target_folder" ] && [ -z "$ROOTFS_DIR" ]; then
  echo -e "${RED}ERROR: target_folder or ROOTFS_DIR must be set${NC}"
  exit 1
fi

# Use ROOTFS_DIR if target_folder not set
if [ -z "$target_folder" ]; then
  target_folder="$ROOTFS_DIR"
fi

echo -e "${YELLOW}Installing webfs-v5 (legacy webserver)${NC}"

# check the webserver package folder
webserver_package_folder="$OPTIONS_DIR/webserver/$package_name"
if [ ! -d "$webserver_package_folder" ]; then
  echo -e "${RED}ERROR: Cannot find the folder '$webserver_package_folder' ${NC}"
  exit 3
fi

# check the webserver package file
webserver_package_file="${webserver_package_folder}/webserver.zip"
if [ ! -f "$webserver_package_file" ]; then
  echo -e "${RED}ERROR: Cannot find the file '$webserver_package_file' ${NC}"
  exit 4
fi

# enable the selected webserver package
current_folder="$PWD"
cd "$target_folder" || exit 7
unzip -oqq "$webserver_package_file"
cd "$current_folder" || exit 8

# Set config destination for webfs-v5 (output for main script)
webserver_cfg_dst="$ROOTFS_DIR/opt/webfs/api/webserver.json"