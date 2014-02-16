#!/bin/bash

function pfx_echo { echo "    $*"; }
function pfx_log { echo "  - $*"; }
function pfx_info { echo "  ~ $*"; }
function pfx_err { echo "  ! $*"; }
function pfx_alert { echo "  ! $*"; }
function pfx_ask { echo "  ? $*"; }

function pfx_prompt() {

    if [[ -n $1 ]]; then pfx_ask "$1 (y/n)"; echo -n '  > '; fi
    read INPUT
    
    until [ "$INPUT" = "y" -o "$INPUT" = "n" ]; do
        pfx_err 'Enter "y" or "n"'
        if [[ -n $1 ]]; then pfx_ask "$1 (y/n)"; echo -n '  > '; fi
        read INPUT
    done
    
    if [[ x"$INPUT" = xy ]]; then
        return 5
    fi
}

function chrome_profile_app_create_all_preset_apps {
  for PROFILE_NAME in Default dev druul guest fvm pfx rs smhmic; do
    chrome_profile_create_app "$PROFILE_NAME"
  done
}

function chrome_profile_app_get_name {
    if [[ x = x"$1" ]]; then
        echo "Google Chrome"
    else
        echo "Google Chrome - ${*}"
    fi
}
function chrome_profile_app_get_path {
    echo "/Applications/$(chrome_profile_app_get_name $*).app"
}

function chrome_profile_app_test {
    # TODO: reload this file to update function def's
    APP_NAME=$(chrome_profile_app_get_name "$PROFILE_NAME")
    APP_PATH=$(chrome_profile_app_get_path "$PROFILE_NAME")
    if [[ -e "$APP_PATH" ]]; then
        EXEC_PATH="$APP_PATH/Contents/MacOS/$APP_NAME"
        echo
        echo "Testing '$APP_PATH' ..."
        echo '--------------------------------------------------'
        cat "$EXEC_PATH"
        echo '--------------------------------------------------'
        bash "$EXEC_PATH" >&2
        echo
    else
        echo "chrome_profile_test_app(): ERROR: '$APP_PATH' does not exist."
    fi
}

function chrome_profile_app_build_and_check {
    echo "Building '$APP_PATH' ..."
    chrome_profile_create_app "$@"
    APP_NAME=$(chrome_profile_app_get_name "$PROFILE_NAME")
    APP_PATH=$(chrome_profile_app_get_path "$PROFILE_NAME")
    EXEC_PATH="$APP_PATH/Contents/MacOS/$APP_NAME"
    if [[ -e "$EXEC_PATH" ]]; then
        echo
        echo "Contents of '$EXEC_PATH' ..."
        echo '--------------------------------------------------'
        cat "$EXEC_PATH"
        echo '--------------------------------------------------'
        #bash "$EXEC_PATH" >&2
        echo
    else
        echo "$0: ERROR: There was an error when building '$EXEC_PATH'."
    fi
}
function chrome_profile_app_build_and_run {
    echo "Building '$APP_PATH' ..."
    chrome_profile_create_app "$@"
    APP_NAME=$(chrome_profile_app_get_name "$PROFILE_NAME")
    APP_PATH=$(chrome_profile_app_get_path "$PROFILE_NAME")
    EXEC_PATH="$APP_PATH/Contents/MacOS/$APP_NAME"
    if [[ -e "$EXEC_PATH" ]]; then
        echo
        echo "Contents of '$EXEC_PATH' ..."
        echo '--------------------------------------------------'
        cat "$EXEC_PATH"
        echo '--------------------------------------------------'
        bash "$EXEC_PATH" >&2
        echo
    else
        echo "$0: ERROR: There was an error when building '$EXEC_PATH'."
    fi
}

function chrome_profile_create_app {

    # Exit if any statement returns a non-true return value (non-zero).
    #set -o errexit
    # Exit on use of an uninitialized variable (TODO: causes error: "!VARNAME: unbound variable")
    #set -o nounset
    set +o errexit
    set +o nounset
    
    if [[ "x--force" = x"$1" ]]; then 
        FORCE=1
        shift
    fi
    
    # unique name of profile
    PROFILE_NAME=$1
    
    # check for required arg
    if [[ x = x"$PROFILE_NAME" ]]; then pfx_err "PROFILE_NAME is empty"; pfx_echo "USAGE: $0 [--force] PROFILE_NAME [CHROME_ARGS]"; return; fi
    
    # name (without .app extension and location of application to be created
    NEW_APP_NAME=$(chrome_profile_app_get_name "$PROFILE_NAME")
    NEW_APP_PATH=$(chrome_profile_app_get_path "$PROFILE_NAME")
    
    # System paths
    SYS_USER_DIR="/Users/$USER"
    SYS_DOWNLOADS_DIR="$SYS_USER_DIR/Downloads"
    
    # System paths - Google Chrome data
    SYS_GOOGLE_DATA_DIR="$SYS_USER_DIR/Library/Application Support/Google"
    SYS_CHROME_DATA_DIR="$SYS_GOOGLE_DATA_DIR/ChromeCustomProfiles" # Default: "$SYS_GOOGLE_DATA_DIR/Chrome"
    
    # Google Chrome ProfileApp paths - data
    APP_CHROME_DATA_DIR="$SYS_CHROME_DATA_DIR/$PROFILE_NAME"
    # Google Chrome ProfileApp paths - cache
    APP_CHROME_CACHE_DIR="$SYS_USER_DIR/Library/Caches/Google/Chrome/allprofiles"
    
    
    #APP_SKEL_DIR="$SYS_GOOGLE_DATA_DIR/ChromeCustomAssets/skel-app"
    CUSTOM_ICON_DIR="$SYS_GOOGLE_DATA_DIR/ChromeCustomAssets/icons"
    CUSTOM_ICON_PATH="$CUSTOM_ICON_DIR/default.png"
    
    ###
    
    # Path to folder containing common extensions. 
    # App will load subdirs as extensions whenever opening app.  
    # Be default, loads all subdirs, but can define subset using CUSTOM_EXT_NAMES.
    CUSTOM_EXT_DIR="$SYS_GOOGLE_DATA_DIR/ChromeCustomAssets/extensions"
    # If empty, every subdir in CUSTOM_EXT_DIR will be used.
    CUSTOM_EXT_NAMES=()
    
    # Path to skel dir. ProfileApp data dir will be initialized with contents.
    # If present, subfolder named '%%PROFILE_NAME%%' will be renamed to PROFILE_NAME.
    CUSTOM_SKEL_DIR="$SYS_GOOGLE_DATA_DIR/ChromeCustomAssets/skel-profile/%%PROFILE_NAME%%"
    
    # ProfileApp default config settings.  
    # After ProfileApp is created, these can be changed from Chrome settings page.
    APP_CHROME_DOWNLOADS_DIR="$SYS_USER_DIR/Downloads/_$PROFILE_NAME"
    
    
    APP_CUSTOM_THEME_PATH="$SYS_GOOGLE_DATA_DIR/ChromeCustomAssets/themes/minimal"
    
    
    # ProfileApp paths
    
    # Find the Google Chrome binary
    CHROME_BIN="/Applications/.Google Chrome/Google Chrome.app/Contents/MacOS/Google Chrome"
    if [[ ! -e "$CHROME_BIN" ]]; then CHROME_BIN="$SYS_USER_DIR/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"; fi
    if [[ ! -e "$CHROME_BIN" ]]; then CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"; fi
    if [[ ! -e "$CHROME_BIN" ]]; then echo "ERROR: Can not find Google Chrome.  Exiting."; exit -1; fi
    
    # Since we are telling Chrome profile dir is the new Chrome Data dir, Chrome will look in subdir for profile settings.
    #if [[ -e "$APP_CHROME_DATA_DIR/Default" ]]; then
      # If a profile already exists, use it
    #  APP_PROFILE_DIR="$APP_CHROME_DATA_DIR/Default"
    #else
      # Else use profile name for folder instead of "Default"
      APP_PROFILE_DIR="$APP_CHROME_DATA_DIR/$PROFILE_NAME"
    #fi
    
    ##############################################################################
    # Create profile data
    
    
            
    # prompt to force close application if it is open
    #RUNNING_PID=$(ps -A | awk "/\/$NEW_APP_NAME\.app/  {print \$1; exit}")
    PID_MATCH="--PFX-ORIGINATING-PROFILEAPP=\\\"?$PROFILE_NAME\\\"?"
    RUNNING_PID=$(ps aux | awk "/$PID_MATCH/  {print \$2; exit}")
    until [[ x"$RUNNING_PID" = x ]]; do
        pfx_echo "Running instances of '$NEW_APP_NAME':"
        pfx_echo "  $(ps aux | head -1)"
        pfx_echo "  $(ps aux | awk /$PID_MATCH/)"
        pfx_prompt "'$NEW_APP_NAME' (pid: $RUNNING_PID) is currently running. Kill process?"
        if [ $? = 5 ]; then
            kill -9 $RUNNING_PID
            # TODO: test when running multiple instances of application
            RUNNING_PID=$(ps aux | awk "/$PID_MATCH/  {print \$2; exit}")
        else
            RUNNING_PID=""
        fi
    done
    
    
    # if profile exists ... 
    if [[ -e "$APP_CHROME_DATA_DIR" ]]; then
    
        pfx_err "There is already a profile at: $APP_CHROME_DATA_DIR"
    
        if [[ "x1" = "x$FORCE" ]]; then 
            # FORCE MODE
            pfx_alert "FORCE MODE: This will erase all data from this directory."; 
            pfx_echo "Press any key to proceed, or Ctrl-C to cancel"; 
            read WAIT
            
            #echo "rm -rfv \"$APP_CHROME_DATA_DIR/*\""
            rm -rf "$APP_CHROME_DATA_DIR"/*
            pfx_log "Wiped $APP_CHROME_DATA_DIR"
            
        else
            pfx_echo "Cancelling."
            return 1
        
            # TODO: implement "rebuild" option
            
            # TODO: if [[ "$1" = "--rebuild" ]]; then  shift; rm -rf "$APP_CHROME_DATA_DIR/*"; fi
            
            # TODO: if profile has not yet been used ... if [[ ! -e "$APP_CHROME_DATA_DIR/Local State" ]]; then
            
            # TODO: recreate certain files
            #for FILENAME in "$APP_CHROME_DATA_DIR/Local State" "$APP_PROFILE_DIR/Preferences"; do
            #    if [[ -e "$FILENAME" ]]; then rm "$FILENAME"; fi
            #done
            
            # TODO: check for and copy individual files  that do not exist
            #if [[ ! -e "$APP_PROFILE_DIR/Local Storage/chrome-extension_hdokiejnpimakedhajhdlcegeplioahd_0.localstorage" ]]; then
            #    cp -R "$SYS_GOOGLE_DATA_DIR/ChromeCustomProfileSkel/%%PROFILE_NAME%%/%%PROFILE_NAME%%/Local Storage" "$APP_PROFILE_DIR"
            #fi
        fi
    fi
    
    if [[ 1=1 ]]; then
        # CREATE/INIT PROFILE
    
        #echo "Creating profile at: $APP_PROFILE_DIR"; #read WAIT
        
        mkdir -p "$APP_CHROME_DATA_DIR"
        
        # copy skel files
        rsync -a "$CUSTOM_SKEL_DIR/" "$APP_CHROME_DATA_DIR"
        #echo "Did rsync"; read WAIT
        #rm -rf "$APP_PROFILE_DIR"
        if [[ -e "$APP_CHROME_DATA_DIR/%%PROFILE_NAME%%" ]]; then
            mv "$APP_CHROME_DATA_DIR/%%PROFILE_NAME%%" "$APP_PROFILE_DIR"
        else
            mkdir "$APP_PROFILE_DIR"
        fi
      
        # replace variables in copied skel files
        for FILENAME in "$APP_CHROME_DATA_DIR/Local State" "$APP_PROFILE_DIR/Preferences"; do
            for VARNAME in PROFILE_NAME APP_CHROME_DATA_DIR SYS_GOOGLE_DATA_DIR APP_CHROME_DOWNLOADS_DIR APP_PROFILE_DIR APP_CUSTOM_THEME_PATH; do
                #echo "replacing: $VARNAME with ${!VARNAME}";
                #sed -i.bak s/STRING_TO_REPLACE/STRING_TO_REPLACE_IT/g "FILEPATH"
                if [[ -e "$FILENAME" ]]; then
                    sed -i.bak "s|%%${VARNAME}%%|${!VARNAME}|g" "$FILENAME"
                fi
            done
            #echo "Did find/replace $FILENAME"; read WAIT
        done
        #echo "find/replace COMPLETE"; read WAIT
    fi
    
    if [[ -e "$APP_PROFILE_DIR" ]]; then
        pfx_info "Profile created at: $APP_PROFILE_DIR"; #read WAIT
    else
        pfx_err 'Profile could not be created. Cancelling.'
        return 1
    fi
    
    ##############################################################################
    # Create app
    
    # in case custom icons were already defined .. dont delete it
    #if [[ -e "$NEW_APP_PATH" ]]; then
    #  rm -r "$NEW_APP_PATH"
    #fi
    
    
    EXECUTABLE_DIR="$NEW_APP_PATH/Contents/MacOS"
    EXECUTABLE_PATH="$EXECUTABLE_DIR/$NEW_APP_NAME"
    
    # if app exists ... 
    if [[ -e "$NEW_APP_PATH" ]]; then
        pfx_info "Application already exists.  Re-writing '$EXECUTABLE_PATH'"
        mkdir -pv "$EXECUTABLE_DIR"
    else
        mkdir -pv "$EXECUTABLE_DIR"
        #rsync -a "$APP_SKEL_DIR"/* "$NEW_APP_PATH"
    fi
    
    #chmod -v +x "$EXECUTABLE_PATH"
    
    if [[ ! -e "$EXECUTABLE_DIR" ]]; then
        pfx_err "Application could not be created at: $EXECUTABLE_DIR"
        pfx_echo 'Cancelling.'
        return 1
    fi
    
    #EXECUTABLE_FILENAME="LaunchChromeProfile_$PROFILE_NAME"
    #cat > "$NEW_APP_PATH/Contents/Info.plist" <<\EOF
    #<?xml version="1.0" encoding="UTF-8"?>
    #<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    #<plist version="1.0">
    #<dict>
    #	<key>CFBundleExecutable</key>
    #	<string>$EXECUTABLE_FILENAME</string>
    #</dict>
    #</plist>
    #EOF
    
    # cmd line args to pass to Chrome
    ARGS=(
        --PFX-ORIGINATING-PROFILEAPP="\\\"$PROFILE_NAME\\\"" \
        --enable-udd-profiles \
        --user-data-dir="\"$APP_CHROME_DATA_DIR\"" \
        --profile-directory="\"$PROFILE_NAME\"" \
        --disk-cache-dir="\"$APP_CHROME_CACHE_DIR\"" \
        #--user-data-dir="\\\"$APP_CHROME_DATA_DIR\\\"" \
        #--profile-directory="\\\"$PROFILE_NAME\\\"" \
        #--disk-cache-dir="\\\"$APP_CHROME_CACHE_DIR\\\"" \
        --disable-bundled-ppapi-flash \
        )
        
    shopt -s nocasematch
    if [[ "$PROFILE_NAME" = *guest* ]]; then 
      # guest profiles
      ARGS=("${ARGS[@]}" --disable-extensions --disable-sync --bwsi --disable-background-mode)
    else
      # non-guest profiles
      ARGS=("${ARGS[@]}" \
        --enable-offline-mode \
        --gaia-profile-info \
        --enable-gaia-profile-info \
        --google-profile-info \
        --enable-profile-shortcut-manager \
        --force-enable-profile-shortcut-manager \
        --force-profile-shortcut-manager \
        --enable-autologin \
        ) #--load-extension="$CUSTOM_EXT_DIR/Lastpass_v3.0.22_0_(hdokiejnpimakedhajhdlcegeplioahd),$CUSTOM_EXT_DIR/Session_Buddy_v3.2.4_0_(edacconmaakjimmfgnblocblbcdcpbko)" \
        #)
      # dev profiles
      # TODO: test flags: --easy-off-store-extension-install --show-component-extension-options --stacked-tab-strip
      if [[ "$PROFILE_NAME" = *dev* ]]; then 
        ARGS=("${ARGS[@]}" \
        --show-component-extension-options \
        --allow-cross-origin-auth-prompt \
        --enable-accessibility-logging \
        --host-rules="\"MAP *.loc 127.0.0.1\""
        #--host-rules="\\\"MAP *.loc 127.0.0.1"\\\"
        )
      fi
    fi
    # append extra args passed to this script
    ARGS=("${ARGS[@]}" "${*:2}")
    
    
    
    
    
    # Create README file.
    
    README_CONTENT_SKEL=$(
        for VARNAME in \
                CUSTOM_SKEL_DIR \
                CUSTOM_EXT_DIR \
                CUSTOM_EXT_NAMES \
            ; do
            printf "   %24s %s %s\n" "$VARNAME" ":" "${!VARNAME}"
        done
    )
    
    README_CONTENT_APP=$(
        for VARNAME in \
                NEW_APP_NAME \
                NEW_APP_PATH \
                APP_CHROME_DATA_DIR \
                APP_CHROME_DOWNLOADS_DIR \
                APP_CHROME_CACHE_DIR \
                CHROME_BIN \
            ; do
            printf "   %24s %s %s\n" "$VARNAME" ":" "${!VARNAME}"
        done
    )
    cat > "$NEW_APP_PATH/README.txt" <<EOF
Chrome ProfileApp
Created at $(date +"%r")
Build script by smhmic@gmail.com

   Profile : $PROFILE_NAME

== APP INFO ========================================================================================
$README_CONTENT_APP

== DATA SOURCES ====================================================================================
$README_CONTENT_SKEL

EOF
    
    
    # TODO: convert the icon and copy into Resources, and create Info.plist - https://s3.amazonaws.com/LACRM_blog/makeApp.sh
    # https://www.lessannoyingcrm.com/blog/2010/08/149/create+application+shortcuts+in+google+chrome+on+a+mac
    
    # create executable
    #exec "$CHROME_BIN" --enable-udd-profiles --user-data-dir="$APP_CHROME_DATA_DIR" --enable-bookmark-undo --enable-enhanced-bookmarks --enable-cast --enable-contacts --enable-panels
    #exec "\$CHROME_BIN" --enable-udd-profiles --user-data-dir="\$APP_CHROME_DATA_DIR" --profile-directory="\$PROFILE_NAME" --disk-cache-dir="/Users/sharris/Library/Caches/Google/Chrome/allprofiles" --enable-bookmark-undo --enable-enhanced-bookmarks --enable-cast --enable-contacts --enable-panels ${*:2}
    # F="$NEW_APP_PATH/Contents/MacOS/$NEW_APP_NAME"
    
    cat > "$EXECUTABLE_PATH" <<EOF
#!/bin/bash

    # Will not work if executed via symlink pointing to this script.
    # http://stackoverflow.com/a/246128/445295
    DIR="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"
    
    # This script opens Chrome with a fork, because if we simply 
    #   exec then Chrome replaces this app's process, which means:
    #   1) default Chrome icon will eventually display in place of this app's icon on the dock
    #   2) Chrome app, instead of this app, will appear by name in running processes (i.e. ps -A)
    
    fork(){ 
        # preview command (in case this is called from console, for debugging)
        #echo;echo; printf '%s \n    ' "\$@"; echo;
        # Run command
        eval \$@
    }
    
    
    runChrome(){ 
    
        # preview command (in case this is called from console, for debugging)
        echo; echo; echo "    \"$CHROME_BIN\""; printf '      %s\n' "\$@"; echo;
        
        exec "$CHROME_BIN" \$@ &
    }
    
    #fork "\"$CHROME_BIN\"" \\
    #    $(printf '"%s" \\\n    ' "\${ARGS[@]}") \\
    #runChrome \\
    #exec "$CHROME_BIN" \\
    #exec "\$DIR/run_chrome" \\
    "$CHROME_BIN" \\
      $(printf '%s \\\n      ' "${ARGS[@]}") \\
      "\$@" 

EOF
    
    chmod -v +x "$EXECUTABLE_PATH"
    
    # set custom icon
    if [[ -e "$CUSTOM_ICON_PATH" ]]; then
    
        if [[ -e "$NEW_APP_PATH/Icon" ]]; then
            pfx_echo "Skipping custom icon; app already has one.";
        else
        
            if [[ $CUSTOM_ICON_PATH =~ ^https?:// ]]; then
                curl -sLo /tmp/icon $CUSTOM_ICON_PATH
                $CUSTOM_ICON_PATH=/tmp/icon
            fi
            
            # resize the image's longest length to 512 
            #sips -Z 512 "$CUSTOM_ICON_PATH" --out /tmp/icon
            #CUSTOM_ICON_PATH=/tmp/icon
        
            # TODO: is it neccessary to check for existence of developer library commands Rez, DeRez and SetFile?
            
            # Take an image and make the image its own icon:
            sips -i "$CUSTOM_ICON_PATH" # 1> /dev/null
            # Extract the icon to its own resource file:
            DeRez -only icns "$CUSTOM_ICON_PATH" > "$CUSTOM_ICON_DIR/tmpicns.rsrc"
            # append this resource to the file you want to icon-ize.
            rm -rf "$NEW_APP_PATH"$'/Icon\r'
            Rez -append "$CUSTOM_ICON_DIR/tmpicns.rsrc" -o "$NEW_APP_PATH"$'/Icon\r'
            # Use the resource to set the icon.
            SetFile -a C "$NEW_APP_PATH"
            # Hide the Icon\r file from Finder.
            SetFile -a V "$NEW_APP_PATH"$'/Icon\r'
            # clean up.
            rm "$CUSTOM_ICON_DIR/tmpicns.rsrc"
        fi
    fi

        
    
    
    echo
    pfx_info "Chrome ProfileApp \"$PROFILE_NAME\" created!" # ($NEW_APP_PATH)
    echo
    
    pfx_prompt "Open application?"
    if [ $? = 5 ]; then
        #exec "$EXECUTABLE_DIR/$EXECUTABLE_FILENAME" &
        echo 'PREVIEW:'
        echo '-----------------------'
        cat "$EXECUTABLE_PATH"
        echo '-----------------------'
        #exec "$EXECUTABLE_DIR/$EXECUTABLE_FILENAME" &
        # Open readme file in browser to easily see AppProfile info
        #exec "$EXECUTABLE_DIR/$EXECUTABLE_FILENAME" "file://$NEW_APP_PATH/README.txt" &
        open "$NEW_APP_PATH" --args "file://$NEW_APP_PATH/README.txt"  && fg
    fi
    
    return 0
}

if [[ x != x"$1" ]]; then 
    chrome_profile_create_app "${@}"
fi
