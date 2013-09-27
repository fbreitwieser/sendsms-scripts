#! /bin/bash

script_dir=$(dirname $0)
cd $script_dir
cat < $script_dir/contacts
echo "-------------------------------"
$script_dir/sender

