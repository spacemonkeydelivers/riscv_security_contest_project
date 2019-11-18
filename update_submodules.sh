#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${DIR}"
rm .updated_marker 2>/dev/null
echo "commencing submodule update procedure..." && \
  git submodule init && \
  git submodule update --recursive && \
  echo "ok" > .updated_marker && \
  echo "all submodules have been successfully updated/initialized"
