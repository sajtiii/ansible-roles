#!/bin/bash

set -uo pipefail

INCLUDE_EXITED=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --include-exited) INCLUDE_EXITED=true ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

docker ps --filter health=unhealthy --format '{{.ID}} {{.Names}}' | while read -r id name; do
  echo "Restarting unhealthy container $name"
  docker restart "$id" > /dev/null || echo "Failed to restart $name"
done

if [ "$INCLUDE_EXITED" = true ]; then
  docker ps --all --filter status=exited --format '{{.ID}} {{.Names}}' | while read -r id name; do
    # Containers without a restart policy are one-shot jobs, not services
    policy=$(docker inspect --format '{{.HostConfig.RestartPolicy.Name}}' "$id")
    if [ "$policy" = "no" ] || [ -z "$policy" ]; then
      continue
    fi
    echo "Starting exited container $name"
    docker start "$id" > /dev/null || echo "Failed to start $name"
  done
fi
