text
lang en_US.UTF-8
keyboard us
timezone US/Eastern
auth --useshadow --passalgo=sha512
selinux --enforcing
firewall --enabled --service=mdns
services --enabled=sshd,NetworkManager,chronyd,initial-setup
autopart
network --bootproto=dhcp --device=link --activate
rootpw --iscrypted --lock $1$1PAq/71w$cJGAbLaOx2dVXMtsK39mO1
shutdown

bootloader --timeout=1

zerombr
clearpart --all --initlabel --disklabel=msdos

# make sure that initial-setup runs and lets us do all the configuration bits
# firstboot --reconfig

%include fedora-repo.ks

%packages
@core
@standard
@hardware-support
# install the default groups for the server evironment since installing the environment is not working
@server-product
@headless-management

@admin-tools
@hardware-support
@python-web
@standard
@system-tools
@text-internet

kernel
kernel-devel
kernel-headers

# remove this in %post
dracut-config-generic
-dracut-config-rescue
# install tools needed to manage and boot arm systems
@arm-tools
-uboot-images-armv7
rng-tools
chrony
initial-setup
-iwl*
-ipw*
-trousers-lib
-usb_modeswitch
-iproute-tc
-generic-release*

# make sure all the locales are available for inital0-setup and anaconda to work
glibc-all-langpacks

# workaround for consequence of RHBZ #1324623: without this, with
# yum-based creation tools, compose fails due to conflict between
# libcrypt and libcrypt-nss. dnf does not seem to have the same
# issue, so this may be dropped when appliance-creator is ported
# to dnf.
libcrypt-nss
-libcrypt
%end

%post

# Setup Raspberry Pi firmware
cp -Pr /usr/share/bcm283x-firmware/* /boot/efi/
mv -f /boot/efi/config-64.txt /boot/efi/config.txt
cp -P /usr/share/uboot/rpi_3/u-boot.bin /boot/efi/rpi3-u-boot.bin

releasever=$(rpm -q --qf '%{version}\n' fedora-release)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-primary
echo "Packages within this disk image"
rpm -qa
# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

dnf -y remove dracut-config-generic

# Disable network service here, as doing it in the services line
# fails due to RHBZ #1369794
/sbin/chkconfig network off

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

# setup systemd to boot to the right runlevel
echo -n "Setting default runlevel to multiuser text mode"
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .

%end
