#!/bin/sh

# https://github.com/boxboat/fixuid
eval "$( fixuid -q )"

eval "$@"
