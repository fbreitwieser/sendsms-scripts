#! /bin/bash

script_dir=$(dirname $0)
ADB=$(cat < $script_dir/adb_location)
$ADB shell am start -a android.intent.action.SENDTO -d sms:06604094602 --es sms_body "Test 2" --ez exit_on_sent true
sleep 1
$ADB shell input keyevent 22
sleep 1
$ADB shell input keyevent 66
