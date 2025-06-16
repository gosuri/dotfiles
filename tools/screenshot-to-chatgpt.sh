#!/bin/bash
# Take screenshot of window to clipboard
screencapture -ic -W
# Open ChatGPT desktop app
open -a "ChatGPT"
# Wait for app to fully load
sleep 1.5
# Activate and paste
osascript -e 'tell application "ChatGPT" to activate' -e 'delay 0.5' -e 'tell application "System Events" to keystroke "v" using command down'
