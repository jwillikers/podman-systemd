#!/usr/bin/env bash
set -o errexit

podman run --systemd always --rm --name test-container -dt localhost/podman-systemd
sleep 5
podman exec test-container podman --version
podman exec test-container systemctl --version
podman stop test-container
