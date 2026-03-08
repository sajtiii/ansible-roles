#!/bin/bash

set -e

FIX=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --fix) FIX=true ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

DOCKER_ARGS=(
  -e RUN_LOCAL=true
  -e VALIDATE_YAML=true
  -e VALIDATE_ANSIBLE=true
  -e VALIDATE_MARKDOWN=true
  -e ANSIBLE_DIRECTORY=/tmp/lint
  -v "$(pwd):/tmp/lint"
)

if [ "$FIX" = true ]; then
  DOCKER_ARGS+=(
    -e FIX_YAML_PRETTIER=true
    -e FIX_ANSIBLE=true
    -e FIX_MARKDOWN=true
  )
fi

docker run "${DOCKER_ARGS[@]}" ghcr.io/super-linter/super-linter:latest
