#!/usr/bin/env bash

set -euxo pipefail

DAY="$1"
roc check "$DAY/main.roc"
roc format "$DAY/main.roc"
roc dev "$DAY/main.roc"
