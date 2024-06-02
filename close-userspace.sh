#!/usr/bin/env bash

# Function to get the list of running GUI applications and their window IDs
running_gui_apps() {
    declare -A app_windows

    # Loop through all open windows (ids)
    for win_id in $(wmctrl -l | cut -d' ' -f1); do

        # Test if window is a normal window
        if xprop -id "$win_id" _NET_WM_WINDOW_TYPE | grep -q '_NET_WM_WINDOW_TYPE_NORMAL'; then

            # Get the process ID of the window
            pid=$(xprop -id "$win_id" _NET_WM_PID | cut -d' ' -f3)

            # Get the process name from the process ID using ps
            pname=$(ps -p "$pid" -o comm=)

            # Add to the associative array with process name as key and window ID as value
            app_windows["$win_id"]="$pname"

        fi

    done

    echo "${!app_windows[@]}"
}

# Function to close all GUI applications gracefully using wmctrl
close_all_applications() {
    local window_ids=("$@")
    local retries=(0.1 0.5 1)

    for retry in "${retries[@]}"; do
        for win_id in "${window_ids[@]}"; do
            # Send the close signal to the window
            wmctrl -ic "$win_id"
        done
        sleep "$retry"

        # Check if all windows are closed
        window_ids=$(running_gui_apps)
        if [ -z "$window_ids" ]; then
            echo "Closed all running GUI applications gracefully."
            return
        fi
    done

    # If not all closed, escalate to SIGQUIT
    escalate_signal "SIGQUIT" "${window_ids[@]}"
}

# Function to escalate signals
escalate_signal() {
    local signal="$1"
    local window_ids=("$@")
    local retries=(0.1 0.2 0.3)

    for retry in "${retries[@]}"; do
        for win_id in "${window_ids[@]}"; do
            # Get the process ID of the window
            pid=$(xprop -id "$win_id" _NET_WM_PID | cut -d' ' -f3)
            # Send the specified signal to the process
            kill -s "$signal" "$pid"
        done
        sleep "$retry"

        # Check if all windows are closed
        window_ids=$(running_gui_apps)
        if [ -z "$window_ids" ]; then
            echo "Closed all running GUI applications with $signal."
            return
        fi
    done

    # If not all closed, escalate to the next signal
    case "$signal" in
        "SIGQUIT")
            escalate_signal "SIGTERM" "${window_ids[@]}"
            ;;
        "SIGTERM")
            escalate_signal "SIGKILL" "${window_ids[@]}"
            ;;
        "SIGKILL")
            echo "Forcefully closed all remaining GUI applications with SIGKILL."
            ;;
    esac
}

# Call the function to get the list of window IDs of running GUI applications
window_ids=$(running_gui_apps)

# Close all running GUI applications
close_all_applications $window_ids
