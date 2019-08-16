#!/bin/bash

set -o xtrace

runner_cmd="$1"
src_path="$2"
input_path="$3"
aux_args="$4"

"$runner_cmd" "$src_path" "$aux_args" <"$input_path"
