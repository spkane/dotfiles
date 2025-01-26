tell application "iTerm"
  activate
  create window with profile "Videos"
  set bounds of front window to {180, 280, 1854, 1072}
  tell current window
    create tab with profile "Videos"
  end tell
  tell first session of first tab of current window
    set name to "Primary"
    delay 3
    write text "sleep 4 && colima stop && kubectl config unset current-context && cd ~/class && clear && reset"
  end tell
  tell first session of second tab of current window
    set name to "Secondary"
    delay 3
    write text "kubectl config unset current-context && dockerstart && sleep 20"
    write text "cd ~/class && clear && reset"
  end tell
end tell
tell application "Visual Studio Code" to activate
tell application "System Events"
  set size of first window of application process "Code" to {929, 411}
  set position of first window of application process "Code" to {100, 200}
end tell
