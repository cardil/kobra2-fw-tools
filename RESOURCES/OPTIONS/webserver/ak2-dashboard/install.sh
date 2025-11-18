#!/bin/bash

# Install ak2-dashboard (modern dashboard)
# Expects from parent script:
#   - project_root
#   - target_folder (or ROOTFS_DIR)
# Outputs:
#   - webserver_cfg_dst: path where webserver.json should be created

# Guard: check required variables
if [ -z "$project_root" ]; then
  echo -e "${RED}ERROR: project_root not set${NC}"
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

echo -e "${YELLOW}Installing ak2-dashboard (modern dashboard)${NC}"

# Check for additional tools needed for building ak2-dashboard
check_tools "git make npm g++"

# Set defaults for ak2-dashboard build (can be overridden by environment variables)
AK2_DASHBOARD_REPO="${AK2_DASHBOARD_REPO:-https://github.com/cardil/ak2-dashboard.git}"
AK2_DASHBOARD_BRANCH="${AK2_DASHBOARD_BRANCH:-feature/ui-overhaul}"

# Create build directory
build_dir="$project_root/build/ak2-dashboard"

# Clone if not exists, otherwise update
if [ ! -d "$build_dir/.git" ]; then
  echo -e "${YELLOW}Cloning ak2-dashboard from $AK2_DASHBOARD_REPO ($AK2_DASHBOARD_BRANCH branch)...${NC}"
  mkdir -p "$build_dir"
  git clone -b "$AK2_DASHBOARD_BRANCH" "$AK2_DASHBOARD_REPO" "$build_dir" || {
    echo -e "${RED}ERROR: Failed to clone ak2-dashboard repository${NC}"
    exit 6
  }
else
  echo -e "${YELLOW}Updating ak2-dashboard repository...${NC}"
  cd "$build_dir" || exit 7
  git fetch origin || {
    echo -e "${RED}ERROR: Failed to fetch updates${NC}"
    exit 7
  }
  git checkout "$AK2_DASHBOARD_BRANCH" || {
    echo -e "${RED}ERROR: Failed to checkout $AK2_DASHBOARD_BRANCH branch${NC}"
    exit 7
  }
  git pull origin "$AK2_DASHBOARD_BRANCH" || {
    echo -e "${RED}ERROR: Failed to pull updates${NC}"
    exit 7
  }
  cd "$project_root" || exit 7
fi

# Build the dashboard
echo -e "${YELLOW}Building ak2-dashboard...${NC}"
cd "$build_dir" || exit 7
make || {
  echo -e "${RED}ERROR: Failed to build ak2-dashboard${NC}"
  exit 8
}

# Check if webserver.zip was created
webserver_package_file="$build_dir/webserver/webserver.zip"
if [ ! -f "$webserver_package_file" ]; then
  echo -e "${RED}ERROR: Build did not produce webserver.zip${NC}"
  exit 9
fi

# Extract the package to target folder
echo -e "${YELLOW}Installing ak2-dashboard to target...${NC}"
current_folder="$PWD"
cd "$target_folder" || exit 7
unzip -oqq "$webserver_package_file"
cd "$current_folder" || exit 8

# Set config destination for ak2-dashboard (output for main script)
mkdir -p "$ROOTFS_DIR/etc/webfs"
webserver_cfg_dst="$ROOTFS_DIR/etc/webfs/webserver.json"