#!/bin/bash

#parse_yaml function
parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# Jump to project root
cd ../../../

# Check YAML files
if [ ! -f .ddevtools.yaml ]; then
    echo ".ddevtools.yaml not found!"
    exit
fi
if [ ! -f .mage.yml ]; then
    echo ".mage.yml not found!"
    exit
fi

# Read yaml file
load_yaml() {
    eval $(parse_yaml .ddevtools.yaml "config_")
    eval $(parse_yaml .mage.yml "mage_")
}

#General variables
NOVAR="Missing entry in the YAML"

load_yaml

# Debug Variables
debugVariables() {
    ( set -o posix ; set ) | less
}

# Helper
testYaml() {
    echo $config_provider_name
    echo $config_provider_package_json
    echo $mage_magephp_environments_develop_user
}

## ddevtools commands >> START ##

node_run_build(){
if [ -n "${config_provider_custom_build}" ]
then
    ${config_provider_custom_build}
elif [ -n "${config_provider_name}" ]
then
    ddev . npm --prefix typo3conf/ext/${config_provider_name}/Resources/Build/ --loglevel=error run-script build
fi
}

node_run_watch(){
if [ -n "${config_provider_custom_watch}" ]
then
    ${config_provider_custom_watch}
elif [ -n "${config_provider_name}" ]
then
    ddev . npm --prefix typo3conf/ext/${config_provider_name}/Resources/Build/ --loglevel=error run-script start
fi
}

node_delete_node_modules(){
if [ -n "${config_provider_name}" ] || [ -n "${config_provider_package_json}" ]
then
    rm -rf web/typo3conf/ext/${config_provider_name}${config_provider_package_json}node_modules
fi
}

node_install_package(){
if [ -n "${config_provider_name}" ] || [ -n "${config_provider_package_json}" ]
then
    ddev . npm --prefix typo3conf/ext/${config_provider_name}${config_provider_package_json} --loglevel=error install
fi
}

## ddevtools commands >> END ##

while [ ! $# -eq 0 ]
do
	case "$1" in
	    --test | -t)
			testYaml
			exit
			;;
		--debug | -d)
			debugVariables
			exit
			;;
		--node_run_build )
			node_run_build
			exit
			;;
		--node_run_watch )
			node_run_watch
			exit
			;;
		--node_delete_node_modules )
			node_delete_node_modules
			exit
			;;
		--node_install_package )
			node_install_package
			exit
			;;
	esac
	shift
done