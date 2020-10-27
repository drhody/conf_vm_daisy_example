#!/bin/bash

set -x
set -e

readonly SLAB_SIZE=2048  # assume IO_TLB_SHIFT=11
readonly NUM_SLABS_PER_MB=$((1024 * 1024 / "${SLAB_SIZE}"))
readonly DEFAULT_SWIOTLB_SIZE_MB=512
readonly ATTR_URL="http://metadata.google.internal/computeMetadata/v1/instance/attributes"
readonly HEADER="Metadata-Flavor:Google"

readonly DAISY_SOURCES=$(curl -sfH "${HEADER}" "${ATTR_URL}/daisy-sources-path")
readonly SWIOTLB_SIZE_MB=$(curl -sfH "${HEADER}" "${ATTR_URL}/swiotlb_size_mb")
readonly ADDITIONAL_SCRIPTS=$(curl -sfH "${HEADER}" "${ATTR_URL}/additional_scripts")

# Install necessary tools to make GVE
apt-get -y upgrade
apt-get -y update
apt-get -y install linux-modules-extra-gcp
echo "gve" > /etc/modules

# Change the SWIOTLB size.
# If swiotlb_size_mb is not specified, set it to be DEFAULT_SWIOTLB_SIZE.
size_mb=$(echo "${SWIOTLB_SIZE_MB}" | grep -oG "[0-9]*" | head -1)
if [[ -z "${size_mb}" ]]
then
  echo swiotlb_size_mb not found. Setting the size of SWIOTLB to "${DEFAULT_SWIOTLB_SIZE_MB}"MB
  size_mb="${DEFAULT_SWIOTLB_SIZE_MB}"
else
  echo Setting the size of SWIOTLB to "${size_mb}"MB
fi
num_slabs=$(("${NUM_SLABS_PER_MB}" * "${size_mb}"))
sed -i "s#GRUB_CMDLINE_LINUX_DEFAULT=\"#GRUB_CMDLINE_LINUX_DEFAULT=\"swiotlb=${num_slabs} #g" /etc/default/grub.d/50-cloudimg-settings.cfg
update-grub

# Execute additional scripts if any
IFS=' '  # additional script names must be space-separated.
read -ra script_array <<< "${ADDITIONAL_SCRIPTS}"
for script in "${script_array[@]}"
do
  echo Running additional script: "${script}"
  gsutil cp "${DAISY_SOURCES}"/additional_scripts/"${script}" /tmp/
  bash /tmp/"${script}"
done

shutdown -h now
