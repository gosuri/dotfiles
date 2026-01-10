#!/bin/bash
# Take screenshot of window to clipboard
screencapture -ic -W
# Open Claude and wait
open -a "Claude"

sleep 1.5

# Activate and paste
osascript -e 'tell application "Claude" to activate' -e 'delay 0.5' -e 'tell application "System Events" to keystroke "v" using command down'
