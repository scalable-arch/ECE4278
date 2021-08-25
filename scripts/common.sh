#!/bin/bash

RUN_DIR=OUTPUT

COMPILE_CMD='vcs'
COMPILE_OPTIONS='-full64 -LDFLAGS -Wl,--no-as-needed -debug_access+r -kdb'

SIM_OPTIONS=''

WAVE_CMD='~/tools/synapticad-19.00c-x64/bin/syncad'

WAVE_OPTIONS='-p wfp'
