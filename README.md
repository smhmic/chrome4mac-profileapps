Chrome Profile App for Mac
===========================

Creates a Mac app for a specific Chrome profile, allowing different profiles to appear as distinct apps in the dock.

## Other Methods

In Windows, it's easy to create shortcuts for different Chrome profiles.  On a Mac, a 'wrapper app' must be created. Besides being more complicated, there are major annoyances in how these 'wrapper apps' behave.

- These app wrappers only work if no other instances of Chrome are running.  (This appears to be an issue within Chrome -- even the `-n` flag for Mac's `open` command does not seem to work.)
- After opening the wrapper app, the custom icon eventually reverts to the default Chrome icon, only restoring the custom icon upon close.

## This Script

This srcript not only automates the process for creating a wrapper app for a Chrome profile, but incorporates fixes for the issue listed above and other improvements. 

- This script allows profile shortcuts to truly act as separate applications by having them use separate appdata directories (instead of just different profile subdirectories).
- The reverting custom icon issue appears to also be caused by Chrome code, and a fix is forthcoming.
 - Chrome is a memory hog! This script uses some command switches and default profile settings that will make Chrome run a little leaner.
 - Allows users to define default settings and extentions for new profiles.
 
### Usage
 
    . chrome_profile_create_app.sh [--force] PROFILE_NAME [CHROME-ARGS]
     
- _[--force]_      
Optional. If given profile name already exists, causes it to be wiped and re-created.
- __PROFILE_NAME__  
Unique name for the profile.  This will used as the suffix to the app name and the appdata directory name.
- _[CHROME-ARGS]_  
Optional. Additional arguments to pass to Chrome.
