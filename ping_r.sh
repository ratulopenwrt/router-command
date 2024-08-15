#!/bin/ash
TARGET_IP="10.0.0.2"
INTERVAL=1
THRESHOLD=35
 # Execute the ping command and capture the output
    PING_RESULT=$(ping -c 1 $TARGET_IP | grep 'time=')
    # Extract the time value from the ping result
    if echo "$PING_RESULT" | grep -q 'time='; then
        # Extract the time value in milliseconds
        PING_TIME=$(echo "$PING_RESULT" | sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p')
        # Convert PING_TIME to an integer for comparison
        PING_TIME_INT=$(echo "$PING_TIME" | cut -d. -f1)  # Extract integer part only
        # Compare the ping time to the threshold
        if [ "$PING_TIME_INT" -lt "$THRESHOLD" ]; then
            echo "Ping is stable"
        else
            reboot
        fi
    else
        echo "Could not connect"
    fi
    
