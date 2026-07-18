#!/usr/bin/env bash
set -euo pipefail

sudo /usr/sbin/cron -f &
cron_pid=$!

"$@" &
app_pid=$!

stop_children() {
    kill -TERM "$cron_pid" "$app_pid" 2>/dev/null || true
}

trap stop_children TERM INT

set +e
wait -n "$cron_pid" "$app_pid"
status=$?
set -e

stop_children
wait "$cron_pid" 2>/dev/null || true
wait "$app_pid" 2>/dev/null || true

exit "$status"
