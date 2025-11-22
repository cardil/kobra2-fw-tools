#!/bin/bash

# check the parameters
if [ $# != 2 ]; then
  echo "usage : $0 <project_root> <webserver_package>"
  exit 1
fi

project_root="$1"
webserver_package="$2"

# Parse pipe-delimited parameters: name|port|api_url
IFS='|' read -r package_name package_port package_api <<< "$webserver_package"

# Set default port if not specified
if [ -z "$package_port" ]; then
  package_port="80"
fi

check_tools "unzip app_version.sh app_model.sh dd printf cp sed patch"

# check the project root folder
if [ ! -d "$project_root" ]; then
  echo -e "${RED}ERROR: Cannot find the folder '$project_root' ${NC}"
  exit 2
fi

# check the target folder
target_folder="$ROOTFS_DIR"
if [ ! -d "$target_folder" ]; then
  echo -e "${RED}ERROR: Cannot find the target folder '$target_folder' ${NC}"
  exit 5
fi

# try to find out the app version (like app_ver="309")
def_target="$ROOTFS_DIR/app/app"
app_ver=$("$app_version_tool" "$def_target")
if [ $? != 0 ]; then
  echo -e "${RED}ERROR: Cannot find the app version ${NC}"
  exit 4
fi

# try to find out the model
app_model=$("$app_model_tool" "$def_target")
if [ $? != 0 ]; then
  echo -e "${RED}ERROR: Cannot find the app model ${NC}"
  exit 5
fi

# Process based on webserver type
webserver_install_script="$OPTIONS_DIR/webserver/$package_name/install.sh"
if [ ! -f "$webserver_install_script" ]; then
  echo -e "${RED}ERROR: Unknown webserver package '$package_name'. Install script not found: $webserver_install_script${NC}"
  exit 10
fi

# Source the webserver-specific install script (no args needed - sourced scripts have access to parent vars)
source "$webserver_install_script"

# Check if webserver_cfg_dst was set by the install script
if [ -z "$webserver_cfg_dst" ]; then
  echo -e "${RED}ERROR: Install script did not set webserver_cfg_dst${NC}"
  exit 11
fi

# Generate webserver.json config with optional API URL (common for both webservers)
if [ -n "$package_api" ]; then
  mqtt_webui_url="http://$package_api"
else
  mqtt_webui_url=""
fi
echo "{\"printer_model\": \"$app_model\", \"update_version\": \"$app_ver\", \"mqtt_webui_url\": \"$mqtt_webui_url\"}" >"$webserver_cfg_dst"

# Add "/opt/bin/webfsd -p port" to rc.local using patch (common for both webservers)
result=$(grep "/opt/bin/webfsd" "$target_folder/etc/rc.local")
if [ -z "$result" ]; then
  # Create temporary patch file with actual port
  temp_patch=$(mktemp)
  sed "s/__PORT__/$package_port/g" "$OPTIONS_DIR/webserver/rc.local.patch" > "$temp_patch"
  
  # Apply patch
  cd "$target_folder/etc" || exit 7
  if ! patch -p0 < "$temp_patch"; then
    echo -e "${RED}ERROR: Failed to patch rc.local. The file may have been modified.${NC}"
    rm -f "$temp_patch"
    exit 6
  fi
  rm -f "$temp_patch"
  cd - > /dev/null || exit 8
fi

# extend the PATH to $project_root/unpacked/squashfs-root/etc/profile
sed -i 's#export PATH="/usr/sbin:/usr/bin:/sbin:/bin"#export PATH="/usr/sbin:/usr/bin:/sbin:/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"#' "$ROOTFS_DIR/etc/profile"

echo -e "${GREEN}SUCCESS: The selected webserver package '$package_name' has been successfully added${NC}"
exit 0
