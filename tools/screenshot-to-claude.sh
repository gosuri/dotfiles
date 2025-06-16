#!/bin/bash
# Take screenshot of window to clipboard
screencapture -ic -W
# Open Claude and wait
open -a "Claude"
sleep 1

# Try to paste with better targeting
osascript <<EOF
tell application "Claude"
    activate
    delay 0.5
end tell
tell application "System Events"
    tell process "Claude"
        keystroke "v" using command down
    end tell
end tell
EOF
