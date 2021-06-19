#!/usr/bin/env bash
set -o errexit

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Generate a container image with Podman and Systemd using Buildah."
   echo
   echo "Syntax: podman-systemd-image.sh [-a|h]"
   echo "options:"
   echo "a     Build for the specified target architecture, i.e. amd64, arm64."
   echo "h     Print this Help."
   echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

# Set variables
ARCHITECTURE="$(podman info --format={{".Host.Arch"}})"

############################################################
# Process the input options. Add options as needed.        #
############################################################
while getopts ":a:h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      a) # Enter a target architecture
         ARCHITECTURE=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

CONTAINER=$(buildah from --arch "$ARCHITECTURE" quay.io/containers/podman:latest)
IMAGE="podman-systemd"

buildah run "$CONTAINER" /bin/sh -c 'dnf -y upgrade'

buildah run "$CONTAINER" /bin/sh -c 'dnf -y reinstall shadow-utils'

buildah run "$CONTAINER" /bin/sh -c 'dnf install -y systemd --nodocs --setopt install_weak_deps=0'

buildah run "$CONTAINER" /bin/sh -c 'dnf clean all -y'

buildah run "$CONTAINER" /bin/sh -c 'cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done'
buildah run "$CONTAINER" /bin/sh -c 'cd /lib/systemd/system/multi-user.target.wants/; for i in *; do [ $i == systemd-user-sessions.service ] || rm -f $i; done'
buildah run "$CONTAINER" /bin/sh -c 'rm -f /lib/systemd/system/multi-user.target.wants/*'
buildah run "$CONTAINER" /bin/sh -c 'rm -f /etc/systemd/system/*.wants/*'
buildah run "$CONTAINER" /bin/sh -c 'rm -f /lib/systemd/system/local-fs.target.wants/*'
buildah run "$CONTAINER" /bin/sh -c 'rm -f /lib/systemd/system/sockets.target.wants/*udev*'
buildah run "$CONTAINER" /bin/sh -c 'rm -f /lib/systemd/system/sockets.target.wants/*initctl*'
buildah run "$CONTAINER" /bin/sh -c 'rm -f /lib/systemd/system/basic.target.wants/*'
buildah run "$CONTAINER" /bin/sh -c 'rm -f /lib/systemd/system/anaconda.target.wants/*'

buildah config --cmd "/usr/sbin/init" "$CONTAINER"

buildah config --label "io.containers.autoupdate=registry" "$CONTAINER"

buildah config --author "Jordan Williams <jordan@jwillikers.com>" "$CONTAINER"

buildah commit "$CONTAINER" "$IMAGE"

buildah rm "$CONTAINER"
