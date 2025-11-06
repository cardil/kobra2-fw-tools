#!/bin/bash

project_root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"

# Source the utils.sh file
source "$project_root/TOOLS/helpers/utils.sh" "$project_root"

check_tools 'dialog'

# select a config file
selected_config_file="options.cfg"
if [ $# -eq 1 ]; then
  cfg_file="$project_root/$1"
  if [ -f "$cfg_file" ]; then
    # it is a configuration file with ext
    selected_config_file="$cfg_file"
  elif [ -f "${cfg_file}.cfg" ]; then
    echo "${cfg_file}.cfg"
    # it is a configuration file without ext
    selected_config_file="${cfg_file}.cfg"
  fi
fi

# check if the auto update is enabled and get the selected tool
auto_install_tool=""
if [ -f "$selected_config_file" ]; then

  # parse the enabled options that have a set value
  options=$(awk -F '=' '{if (! ($0 ~ /^;/) && ! ($0 ~ /^#/) && ! ($0 ~ /^$/) && ! ($2 == "")) print $1}' "$selected_config_file")

  # for each enabled option
  for option in $options; do
    parameters=$(awk -F '=' "{if (! (substr(\$0,1,1) == \"#\") && ! (substr(\$0,1,1) == \";\") && ! (\$1 == \"\") && ! (\$2 == \"\") && (\$1 ~ /$option/ ) ) print \$2}" "$selected_config_file" | head -n 1)
    # replace the project root requests
    parameter="${parameters/@/"$project_root"}"
    # remove the leading and ending double quotes
    parameter=$(echo "$parameter" | sed -e 's/^"//' -e 's/"$//')
    # remove the leading and ending single quotes
    parameter=$(echo "$parameter" | sed -e 's/^'\''//' -e 's/'\''$//')
    if [ "$option" = "auto_install" ]; then
      auto_install_tool="$parameter"
    fi
  done
fi

# use the auto install tool if present
if [ -f "$auto_install_tool" ]; then
  # Ask if the user wants to attempt to auto install the update now. If yes then run the auto install script
  if dialog --keep-tite --yesno "Do you want to attempt to auto install the firmware via SSH?" 6 40; then
    # Run the auto update tool
    if [[ "$auto_install_tool" == *.py ]]; then
      python3 "$auto_install_tool"
    else
      "$auto_install_tool"
    fi
  fi
fi
