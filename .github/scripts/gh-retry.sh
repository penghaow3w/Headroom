#!/usr/bin/env bash
# Retry transient GitHub transport failures; preserve permanent failures.
gh_retry() {
  local attempt status output
  for attempt in 1 2 3; do
    if output=$(gh "$@" 2>&1); then
      printf '%s\n' "$output"
      return 0
    else
      status=$?
    fi
    printf '%s\n' "$output" >&2
    if [[ "$attempt" == 3 ]] || ! grep -Eqi 'HTTP 50[234]|HTTP 429|timed out|connection reset|TLS handshake timeout|temporary failure' <<<"$output"; then
      return "$status"
    fi
    sleep "$((attempt * 2))"
  done
}
