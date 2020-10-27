#!/bin/bash
# This script creates a new Ubuntu image compatible with Confidential VM in a
# one shot. For better understanding about the image creation process, please
# read the "Step-by-step Instructions" section in the online documentation.

set -e

readonly CONF_NAME="test-conf-vm-example"
readonly COMPUTE_ZONE_NAME="us-central1-a"
readonly DAISY_LINUX_BIN_URL="https://storage.googleapis.com/compute-image-tools/release/linux/daisy"
readonly DAISY_MAC_BIN_URL="https://storage.googleapis.com/compute-image-tools/release/darwin/daisy"

GCE_ACCOUNT="${1}"
PROJECT="${2}"

print_usage(){
  echo 'Usage: ubuntu_1804_conf_vm_example_oneshot.sh [your GCE account name] [your GCE project name]'
}

# gcloud configuration
if [[ -z "$(gcloud config configurations list | grep ${CONF_NAME})" ]]; then
  # If configuration does not exist, make a new one.
  if [[ -z "${GCE_ACCOUNT}" ]] || [[ -z "${PROJECT}" ]]; then
    echo 'Error: GCE account and/or project are not specified.'
    print_usage
    exit 1
  fi
  gcloud config configurations create "${CONF_NAME}"
  gcloud config set account "${GCE_ACCOUNT}"
  gcloud config set compute/zone "${COMPUTE_ZONE_NAME}"
  gcloud config set project "${PROJECT}"
else
  # If configuration already exists:
  #  - If account and project are specified as the command line args, update
  #    the configuration.
  #  - Otherwise, reuse the existing config if it is valid.
  gcloud config configurations activate "${CONF_NAME}"

  if [[ ! -z "${GCE_ACCOUNT}" ]]; then
    gcloud config set account "${GCE_ACCOUNT}"
  else
    GCE_ACCOUNT="$(gcloud config list 2>/dev/null | grep account | cut -d' ' -f 3)"
  fi

  if [[ ! -z "${PROJECT}" ]]; then
    gcloud config set project "${PROJECT}"
  else
    PROJECT="$(gcloud config list 2>/dev/null | grep project | cut -d' ' -f 3)"
  fi

  if [[ -z "${GCE_ACCOUNT}" ]] || [[ -z "${PROJECT}" ]]; then
    echo 'Error: GCE account and/or project are not specified.'
    print_usage
    exit 1
  fi
fi

# gcloud authentication
if (! gcloud auth print-access-token > /dev/null 2>&1); then
  gcloud auth login
fi

if (! gcloud auth application-default print-access-token > /dev/null 2>&1); then
  gcloud auth application-default login
fi

# Download the Daisy binary if not exists.
daisy_cmd=""
if [[ -z "$(which daisy)" ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    DAISY_BIN_URL="${DAISY_MAC_BIN_URL}"
  elif [[ "$(uname -s)" == "Linux" ]]; then
    DAISY_BIN_URL="${DAISY_LINUX_BIN_URL}"
  else
    echo 'Error: Currently only Mac and Linux are supported'
    exit 1
  fi
  wget -O daisy "${DAISY_BIN_URL}"
  chmod +x daisy
  daisy_cmd="$(pwd)/daisy"
else
  daisy_cmd="$(which daisy)"	
fi

# Execute the Daisy workflow to create an Ubuntu 1804 Confidential VM image.
"${daisy_cmd}" -project "${PROJECT}" ubuntu_1804_conf_vm_example.wf.json
gcloud compute images describe ubuntu-1804-conf-vm-example
