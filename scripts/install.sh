#!/usr/bin/env bash

HERE=$(dirname $0)
THEMEDIRECTORY=$(cd $HERE/.. && pwd)
FIREFOXFOLDER=~/.mozilla/firefox
PROFILEPATH=""
GNOMISHEXTRAS=false
DRY=false

while getopts 'f:p:gdh' flag; do
	case "${flag}" in    
		f) FIREFOXFOLDER="${OPTARG}" ;;
    p) PROFILEPATH="${OPTARG}" ;;
    g) GNOMISHEXTRAS=true ;;
    d) DRY=true ;;
    h) echo "Usage: $0 [-f <firefox folder>] [-p <profile path>] [-g] [-d] [-h]"
       echo "Options:"
       echo "  -f <firefox folder>  Set the Firefox folder path. Default is ~/.mozilla/firefox/"
       echo "  -p <profile path>    Set the profile path. Displays menu when unset."
       echo "  -g                   Enable GNOMISH extras."
       echo "  -d                   Dry run. Do not make any changes."
       echo "  -h                   Display this help message."
       exit 0 ;;
	esac
done

if test -z "$PROFILEPATH"; then
  if test -f "${FIREFOXFOLDER}/profiles.ini"; then
    declare -A PROFILES
    counter=1
    for i in $(awk -F= -f $HERE/awkfile ${FIREFOXFOLDER}/profiles.ini); do
      IFS=: read -ra PROF <<< "${i}"
      if [ "${PROF[3]}" -eq "1" ]; 
      then
        list_number=0
      else
        list_number=$counter
        ((counter++))
      fi
      for k in "${!PROF[@]}"; do
        PROFILES[${list_number}, $k]=${PROF[$k]}
      done
    done

    PROFILENUMBER=-1
    while ((PROFILENUMBER < 0 || PROFILENUMBER >= counter)); do
      echo "Select a profile (default is 0):"
        for i in $(seq 0 $((counter-1))); do
          echo "${i}) ${PROFILES[${i}, 1]} - ${PROFILES[${i}, 0]}"
        done
      read -p ">" PROFILENUMBER
      if [ -z "$PROFILENUMBER" ]; then
        PROFILENUMBER=0
      fi
    done

    PROFILEPATH=${PROFILES[${PROFILENUMBER}, 0]}
    if [ "${PROFILES[${PROFILENUMBER}, 2}]}" == "0" ]; then
      TARGETPATH=$PROFILEPATH
    else
      TARGETPATH="$FIREFOXFOLDER/$PROFILEPATH"
    fi
  fi
fi

if ! cd $TARGETPATH 2> /dev/null; then
echo "Profile path not found."
exit 1
fi

shopt -s extglob

if [ "${DRY}" = true ]; then
  echo "Dry run. No changes will be made."
  echo "List of files to be copied:"
  ls -R $THEMEDIRECTORY/!(.git|.github|scripts|*.code-workspace|README.md)
  exit 0
fi

echo "Installing theme in $PWD"

mkdir -p chrome
cd chrome

# Copy theme repo inside
echo "Copying repo in $PWD"
cp -R $THEMEDIRECTORY/!(.git|.github|scripts|*.code-workspace|README.md) $PWD

# Create single-line user CSS files if non-existent or empty.
[[ -s userChrome.css ]] || echo >> userChrome.css

# Import this theme at the beginning of the CSS files. #TODO Check if exists first
sed -i '1s/^/@import "firefox-nordic-theme\/userChrome.css";\n/' userChrome.css

# If GNOMISH extras enabled, import it in customChrome.css.
if [ "${GNOMISHEXTRAS}" = true ]; then
	echo "Enabling GNOMISH extra features"
  [[ -s customChrome.css ]] || echo >> customChrome.css #TODO Check if exists first
  sed -i '1s/^/@import "theme\/hide-single-tab.css";\n/' customChrome.css
	sed -i '2s/^/@import "theme\/matching-autocomplete-width.css";\n/' customChrome.css
fi

# Symlink user.js to firefox-nordic-theme one.
echo "Set configuration user.js file"
ln -sf configuration/user.js ../user.js

echo "Done."