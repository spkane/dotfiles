tell application "iTerm"
  activate
  create window with profile "Class"
  tell current window
    create tab with profile "Class"
  end tell
  tell first session of first tab of current window
    set name to "Primary"
    write text "sleep 4 && colima stop && kubectl config unset current-context && cd ~/class && code . && clear && reset"
  end tell
  tell first session of second tab of current window
    set name to "Secondary"
    write text "kubectl config unset current-context && dockerstart && sleep 20"
    write text "cd ~/class && clear && reset"
  end tell
end tell
