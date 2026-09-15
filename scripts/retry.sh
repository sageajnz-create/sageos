#!/usr/bin/env bash
# Retry a command with exponential backoff.
# Disk-image CI wraps registry pulls so a transient quay.io 5xx (podman exit 125)
# does not fail the overnight QCOW2 gate on the first blip.
set -euo pipefail

attempts=5
delay_seconds=15

usage() {
    echo "usage: retry.sh [--attempts N] [--delay-seconds N] [--] command [args...]" >&2
    exit 2
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --attempts)
            [[ $# -ge 2 ]] || usage
            attempts="$2"
            shift 2
            ;;
        --delay-seconds)
            [[ $# -ge 2 ]] || usage
            delay_seconds="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            usage
            ;;
        *)
            break
            ;;
    esac
done

[[ $# -ge 1 ]] || usage
[[ "${attempts}" =~ ^[1-9][0-9]*$ ]] || usage
[[ "${delay_seconds}" =~ ^[0-9]+$ ]] || usage

attempt=1
delay="${delay_seconds}"
while true; do
    rc=0
    "$@" || rc=$?
    if [[ "${rc}" -eq 0 ]]; then
        exit 0
    fi
    if ((attempt >= attempts)); then
        echo "ERROR: command failed after ${attempts} attempts (exit ${rc}): $*" >&2
        exit "${rc}"
    fi
    echo "WARN: command failed (attempt ${attempt}/${attempts}, exit ${rc}); retrying in ${delay}s: $*" >&2
    sleep "${delay}"
    attempt=$((attempt + 1))
    delay=$((delay * 2))
done
