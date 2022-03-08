#!/bin/bash
function f.checkdpkg(){
	DPKGLOCKED=$(lsof /var/lib/dpkg/lock 2>/dev/null | grep -c "/var/lib/dpkg/lock"); WAITCOUNT="0"
	if [ "$DPKGLOCKED" -ge "1" ];then
		until [ "$DPKGLOCKED" = "0" ] || [ "$WAITCOUNT" = "60" ]; do
			DPKGLOCKED=$(lsof /var/lib/dpkg/lock 2>/dev/null | grep -c "/var/lib/dpkg/lock"); ((WAITCOUNT++))
		done
	fi
	if [ "$WAITCOUNT" -ge "120" ]; then echo "Timed out waiting on dpkg lock to clear."; echo "manually clearing dpkg lock"; rm -f /var/lib/dpkg/lock; fi
}
kernel=$(/bin/uname -r | grep -c "4.15")
if [ "$kernel" = "0" ]; then
echo "4.15-rc7-mining_os60 kernel installer"
echo "Downloading necessary packages...."
sudo wget http://example.com/packages/1.3.0-testing/gpulist -O /usr/share/initramfs-tools/scripts/init-top/gpulist
sudo chmod +x /usr/share/initramfs-tools/scripts/init-top/gpulist
sudo wget http://example.com/packages/1.3.0-testing/kernel-update-files.tar.xz -O /tmp/kernel-update-files.tar.xz
cd /tmp
sudo tar xf /tmp/kernel-update-files.tar.xz
sudo /usr/bin/apt-get -y purge amdgpu-firmware-bin
f.checkdpkg
sudo sed -ie 's/pp_voltage/pp_core_vddc/g' /opt/mining_os/sbin/mining_os-oc-amdgpu
sudo sed -ie 's/pp_voltage/pp_core_vddc/g' /opt/mining_os/sbin/mining_os-readdata
sudo dpkg -i /tmp/kernel-update-files/linux-firmware_1.170-mining_os3_all.deb \
/tmp/kernel-update-files/linux-firmware-amdgpu-misc-mining_os1_all.deb \
/tmp/kernel-update-files/linux-firmware-amdgpu-polaris_1.170-mining_os1_all.deb \
/tmp/kernel-update-files/linux-firmware-amdgpu-vega_1.170-mining_os1_all.deb \
/tmp/kernel-update-files/linux-firmware-radeon-mining_os1_all.deb \
/tmp/kernel-update-files/libopencl1-amdgpu-pro_17.40.2712-510357-mining_os11_amd64.deb \
/tmp/kernel-update-files/opencl-amdgpu-pro-icd_17.40.2712-510357-mining_os11_amd64.deb \
/tmp/kernel-update-files/linux-headers-4.15.0-rc7-mining_os60_4.15.0-rc7-mining_os60-2_amd64.deb \
/tmp/kernel-update-files/linux-image-4.15.0-rc7-mining_os60_4.15.0-rc7-mining_os60-2_amd64.deb \
/tmp/kernel-update-files/linux-libc-dev_4.15.0-rc7-mining_os60-2_amd64.deb

echo "Kernel update complete, syncing disks and waiting 30 seconds, and initiating a soft reboot."
sync
sleep 30
else
echo "Kernel already installed"
fi
