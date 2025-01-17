#!/usr/bin/env bash

THEMEDIRECTORY=$(cd `dirname $0` && cd .. && pwd);

case "$(uname -s)" in
    Darwin*)    FIREFOXFOLDER=~/Library/Application\ Support/Firefox/;;
    *)          FIREFOXFOLDER=~/.mozilla/firefox/;;
esac

PROFILENAME="";
FXACEXTRAS=false;
CHROMEFOLDER="chrome";


# Get installation options
while getopts 'f:p:eh' flag; do
	case "${flag}" in
		f) FIREFOXFOLDER="${OPTARG}" ;;
		p) PROFILENAME="${OPTARG}" ;;
		e) FXACEXTRAS=true ;;
        h)
            echo "Sweet_Pop! Install script usage: ./install.sh [ options ... ]"
            echo "where options include:"
            echo
            echo "  -f <firefox_folder> (Set custom Firefox folder path)"
            echo "  -p <profile_name>   (Set custom profile name)"
            echo "  -e                  (Install fx-autoconfig - Runs sudo to copy mozilla.cfg and local-settings.js to Application Binary folder)"
            echo "  -h                  (Show help message)"
            exit 0
            ;;
	esac
done


# Check if Firefox profiles.ini is installed or not
PROFILES_FILE="${FIREFOXFOLDER}/profiles.ini"
if [ ! -f "${PROFILES_FILE}" ]; then
	>&2 echo "Failed to locate profiles.ini at ${FIREFOXFOLDER}
Exiting..."
	exit 1
fi

echo
echo "Profiles file found..."


# Define default Profile folder path else use -p option
if [ -z "$PROFILENAME" ]; then
    PROFILEFOLDER="${FIREFOXFOLDER}/$(grep -zoP '\[Install.*?\]\nDefault=\K(.*?)\n' $PROFILES_FILE | tr -d '\0')"
else
    PROFILEFOLDER="${FIREFOXFOLDER}/${PROFILENAME}"
fi


# Enter Firefox profile folder if it exists
if [ ! -d "$PROFILEFOLDER" ]; then
    >&2 echo "Failed to locate Profile folder at ${PROFILEFOLDER}
Exiting..."
	exit 1
fi

cd $PROFILEFOLDER


# Copy theme repository inside chrome folder
echo
echo "Installing Sweet_Pop! in ${PWD}"

# Create a chrome directory if it doesn't exist else take a backupold chrome folder
if [ -d "$CHROMEFOLDER" ]; then
    echo "Moving existing $CHROMEFOLDER to ${CHROMEFOLDER}_bak"
    mv --backup=t $CHROMEFOLDER "${CHROMEFOLDER}_bak" || { exit 1; }
fi

mkdir -p $CHROMEFOLDER
cd $CHROMEFOLDER

cp -a "${THEMEDIRECTORY}/." $PWD


# Symlink user.js to that of Sweet_Pop!
echo
echo "Setting configuration user.js file..."

if [ -f ../user.js ]; then
    echo "Moving existing user.js to user.js.bak"
    mv --backup=t ../user.js ../user.js.bak || { exit 1; }
fi

ln -fs "`pwd`/programs/user.js" ../user.js


# If FXACEXTRAS extras enabled, install necessary files
if [ "$FXACEXTRAS" = true ] ; then
    APPLICATIONFOLDER=$(readlink -f `which firefox` | xargs -I{} dirname {})

    echo
    echo "Enabling userChrome.js manager (fx-autoconfig)..."
    mkdir -p "${PWD}/utils"
    cd "${PWD}/utils"

    curl -sOL "https://raw.githubusercontent.com/MrOtherGuy/fx-autoconfig/master/profile/chrome/utils/boot.jsm" || { echo "Failed to fetch fx-autoconfig"; echo "Exiting..."; exit 1; }

    cat << EOF > chrome.manifest
content userchromejs ./
content userscripts ../script/
content userchrome ../
resource content-accessible chrome://userchrome/content/layout/contentaccessible/ contentaccessible=yes
EOF

    echo "Enabling Navbar Toolbar Button Slider..."
    cd ../script
    curl -sOL "https://raw.githubusercontent.com/aminomancer/uc.css.js/master/JS/navbarToolbarButtonSlider.uc.js" || { echo "Failed to fetch Navbar Toolbar Button Slider"; echo "Exiting..."; exit 1; }
    cd ../

    echo
    echo "Copying mozilla.cfg and local-settings.js to ${APPLICATIONFOLDER}"
    chmod +x "${PWD}/programs/install-cfg.sh"
    sudo "${PWD}/programs/install-cfg.sh" $APPLICATIONFOLDER || { echo "Exiting..."; exit 1; }
fi

echo
echo "Done!"
echo "Note: Restart twice to apply changes"
