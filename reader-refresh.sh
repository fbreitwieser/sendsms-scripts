#! /bin/bash

script_dir=$(dirname $0)
$(cat < $script_dir/command)
watch $(cat < $script_dir/command)
