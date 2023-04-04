#!/bin/env bash

set -eu

source "$(dirname "${BASH_SOURCE[0]}")/setup.sh"
"$(dirname "${BASH_SOURCE[0]}")/buildAndChecksum.sh"

