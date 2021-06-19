#!/usr/bin/env bash
set -o errexit

podman run --rm --name test-container -dt localhost/podman-systemd
#podman run --volume --rm --name test-container -it localhost/podman-systemd
sleep 5
podman exec test-container podman --version
podman exec test-container systemctl --version
podman stop test-container
