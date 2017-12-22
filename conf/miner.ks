%include fedora-disk-base.ks

part / --size 6144 --fstype ext4
services --enabled=sshd,NetworkManager,chronyd
network --bootproto=dhcp --device=link --activate --onboot=on
#bootloader --timeout=1 --append="no_timer_check console=tty1 console=ttyS0,115200n8 debug"
bootloader --timeout=1
rootpw --iscrypted --lock $1$1PAq/71w$cJGAbLaOx2dVXMtsK39mO1
#user --name=liveuser --groups=wheel,liveuser --password=liveuser

%packages
@base-x
-@guest-desktop-agents
-@fonts
-@input-methods
-@dial-up
-@multimedia
-@printing

# install tools needed to manage and boot arm systems
-@arm-tools
-uboot-images-armv7

# install the default groups for the server evironment since installing the environment is not working
@server-product
@standard
@headless-management
-initial-setup-gui
-generic-release*
@development-tools
@admin-tools
@system-tools
@text-internet
@python-web

# Explicitly specified here:
# <notting> walters: because otherwise dependency loops cause yum issues.
kernel
kernel-devel
kernel-modules
kernel-modules-extra

# The point of a live image is to install
anaconda
@anaconda-tools

# Without this, initramfs generation during live image creation fails: #1242586
dracut-live
grub2-efi
syslinux

# anaconda needs the locales available to run for different locales
glibc-all-langpacks

# Libraries for ethminer
ocl-icd-devel
clinfo
-beignet
-pocl
-mesa-libOpenCL

# save some space
-mpage
-sox
-hplip
-numactl
-isdn4k-utils
-autofs
# smartcards won't really work on the livecd.
-coolkey

# scanning takes quite a bit of space :/
-xsane
-xsane-gimp
-sane-backends

%end

%post

dnf update -y

mkdir -p /home/liveuser

# add liveuser user with no passwd
#action "Adding live user" useradd \$USERADDARGS -c "Live System User" liveuser
echo "Adding live user"
/usr/sbin/useradd -M -c "Live System User" liveuser
passwd -d liveuser 
passwd -d root 
/usr/sbin/usermod -aG wheel liveuser
chown -R liveuser:liveuser /home/liveuser

# setup systemd to boot to the right runlevel
echo -n "Setting default runlevel to multiuser text mode"
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .

cat > /etc/rc.d/init.d/livesys << EOF
#!/bin/bash
#
# live: Init script for live image
#
# chkconfig: 345 00 99
# description: Init script for live image.
### BEGIN INIT INFO
# X-Start-Before: display-manager chronyd
### END INIT INFO

. /etc/init.d/functions

if ! strstr "\`cat /proc/cmdline\`" rd.live.image || [ "\$1" != "start" ]; then
    exit 0
fi

if [ -e /.liveimg-configured ] ; then
    configdone=1
fi

exists() {
    which \$1 >/dev/null 2>&1 || return
    \$*
}

livedir="LiveOS"
for arg in \`cat /proc/cmdline\` ; do
  if [ "\${arg##rd.live.dir=}" != "\${arg}" ]; then
    livedir=\${arg##rd.live.dir=}
    return
  fi
  if [ "\${arg##live_dir=}" != "\${arg}" ]; then
    livedir=\${arg##live_dir=}
    return
  fi
done

# enable swaps unless requested otherwise
swaps=\`blkid -t TYPE=swap -o device\`
if ! strstr "\`cat /proc/cmdline\`" noswap && [ -n "\$swaps" ] ; then
  for s in \$swaps ; do
    action "Enabling swap partition \$s" swapon \$s
  done
fi
if ! strstr "\`cat /proc/cmdline\`" noswap && [ -f /run/initramfs/live/\${livedir}/swap.img ] ; then
  action "Enabling swap file" swapon /run/initramfs/live/\${livedir}/swap.img
fi

mountPersistentHome() {
  # support label/uuid
  if [ "\${homedev##LABEL=}" != "\${homedev}" -o "\${homedev##UUID=}" != "\${homedev}" ]; then
    homedev=\`/sbin/blkid -o device -t "\$homedev"\`
  fi

  # if we're given a file rather than a blockdev, loopback it
  if [ "\${homedev##mtd}" != "\${homedev}" ]; then
    # mtd devs don't have a block device but get magic-mounted with -t jffs2
    mountopts="-t jffs2"
  elif [ ! -b "\$homedev" ]; then
    loopdev=\`losetup -f\`
    if [ "\${homedev##/run/initramfs/live}" != "\${homedev}" ]; then
      action "Remounting live store r/w" mount -o remount,rw /run/initramfs/live
    fi
    losetup \$loopdev \$homedev
    homedev=\$loopdev
  fi

  # if it's encrypted, we need to unlock it
  if [ "\$(/sbin/blkid -s TYPE -o value \$homedev 2>/dev/null)" = "crypto_LUKS" ]; then
    echo
    echo "Setting up encrypted /home device"
    plymouth ask-for-password --command="cryptsetup luksOpen \$homedev EncHome"
    homedev=/dev/mapper/EncHome
  fi

  # and finally do the mount
  mount \$mountopts \$homedev /home
  # if we have /home under what's passed for persistent home, then
  # we should make that the real /home.  useful for mtd device on olpc
  if [ -d /home/home ]; then mount --bind /home/home /home ; fi
  [ -x /sbin/restorecon ] && /sbin/restorecon /home
  if [ -d /home/liveuser ]; then USERADDARGS="-M" ; fi
}

findPersistentHome() {
  for arg in \`cat /proc/cmdline\` ; do
    if [ "\${arg##persistenthome=}" != "\${arg}" ]; then
      homedev=\${arg##persistenthome=}
      return
    fi
  done
}

if strstr "\`cat /proc/cmdline\`" persistenthome= ; then
  findPersistentHome
elif [ -e /run/initramfs/live/\${livedir}/home.img ]; then
  homedev=/run/initramfs/live/\${livedir}/home.img
fi

# if we have a persistent /home, then we want to go ahead and mount it
if ! strstr "\`cat /proc/cmdline\`" nopersistenthome && [ -n "\$homedev" ] ; then
  action "Mounting persistent /home" mountPersistentHome
fi

if [ -n "\$configdone" ]; then
  exit 0
fi

# add liveuser user with no passwd
action "Adding live user" useradd \$USERADDARGS -c "Live System User" liveuser
passwd -d liveuser > /dev/null
usermod -aG wheel liveuser > /dev/null

# Remove root password lock
passwd -d root > /dev/null

# turn off firstboot for livecd boots
systemctl --no-reload disable firstboot-text.service 2> /dev/null || :
systemctl --no-reload disable firstboot-graphical.service 2> /dev/null || :
systemctl stop firstboot-text.service 2> /dev/null || :
systemctl stop firstboot-graphical.service 2> /dev/null || :

# don't use prelink on a running live image
sed -i 's/PRELINKING=yes/PRELINKING=no/' /etc/sysconfig/prelink &>/dev/null || :

# turn off mdmonitor by default
systemctl --no-reload disable mdmonitor.service 2> /dev/null || :
systemctl --no-reload disable mdmonitor-takeover.service 2> /dev/null || :
systemctl stop mdmonitor.service 2> /dev/null || :
systemctl stop mdmonitor-takeover.service 2> /dev/null || :

# don't enable the gnome-settings-daemon packagekit plugin
gsettings set org.gnome.software download-updates 'false' || :

# don't start cron/at as they tend to spawn things which are
# disk intensive that are painful on a live image
systemctl --no-reload disable crond.service 2> /dev/null || :
systemctl --no-reload disable atd.service 2> /dev/null || :
systemctl stop crond.service 2> /dev/null || :
systemctl stop atd.service 2> /dev/null || :

# Don't sync the system clock when running live (RHBZ #1018162)
sed -i 's/rtcsync//' /etc/chrony.conf

# Mark things as configured
touch /.liveimg-configured

# add static hostname to work around xauth bug
# https://bugzilla.redhat.com/show_bug.cgi?id=679486
# the hostname must be something else than 'localhost'
# https://bugzilla.redhat.com/show_bug.cgi?id=1370222
echo "localhost-live" > /etc/hostname
#systemctl enable claymore
#systemctl start claymore.service

systemctl enable ethminer
systemctl start ethminer

mkdir /tmp/build \
  && cd /tmp/build
  && curl -OL https://www2.ati.com/drivers/linux/rhel7/amdgpu-pro-17.50-511655.tar.xz -e http://support.amd.com/en-us/kb-articles/Pages/Installation-Instructions-for-amdgpu-Graphics-Stacks.aspx \
  && tar -Jxvf amdgpu-pro-17.50-511655.tar.xz \
  && cd amdgpu-pro-17.50-511655 \
  && ./amdgpu-install -y 
  && cd - && rm -rf /tmp/build

EOF

# bah, hal starts way too late
cat > /etc/rc.d/init.d/livesys-late << EOF
#!/bin/bash
#
# live: Late init script for live image
#
# chkconfig: 345 99 01
# description: Late init script for live image.

. /etc/init.d/functions

if ! strstr "\`cat /proc/cmdline\`" rd.live.image || [ "\$1" != "start" ] || [ -e /.liveimg-late-configured ] ; then
    exit 0
fi

exists() {
    which \$1 >/dev/null 2>&1 || return
    \$*
}

touch /.liveimg-late-configured

# read some variables out of /proc/cmdline
for o in \`cat /proc/cmdline\` ; do
    case \$o in
    ks=*)
        ks="--kickstart=\${o#ks=}"
        ;;
    xdriver=*)
        xdriver="\${o#xdriver=}"
        ;;
    esac
done

# if liveinst or textinst is given, start anaconda
if strstr "\`cat /proc/cmdline\`" liveinst ; then
   plymouth --quit
   /usr/sbin/liveinst \$ks
fi
if strstr "\`cat /proc/cmdline\`" textinst ; then
   plymouth --quit
   /usr/sbin/liveinst --text \$ks
fi

EOF


chmod 755 /etc/rc.d/init.d/livesys
/sbin/restorecon /etc/rc.d/init.d/livesys
/sbin/chkconfig --add livesys

chmod 755 /etc/rc.d/init.d/livesys-late
/sbin/restorecon /etc/rc.d/init.d/livesys-late
/sbin/chkconfig --add livesys-late

# enable tmpfs for /tmp
systemctl enable tmp.mount

# make it so that we don't do writing to the overlay for things which
# are just tmpdirs/caches
# note https://bugzilla.redhat.com/show_bug.cgi?id=1135475
cat >> /etc/fstab << EOF
vartmp   /var/tmp    tmpfs   defaults   0  0
EOF

# work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
releasever=$(rpm -q --qf '%{version}\n' --whatprovides system-release)
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# make sure there aren't core files lying around
rm -f /core*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

# convince readahead not to collect
# FIXME: for systemd

echo 'File created by kickstart. See systemd-update-done.service(8).' \
    | tee /etc/.updated >/var/.updated

# Drop the rescue kernel and initramfs, we don't need them on the live media itself.
# See bug 1317709
rm -f /boot/*-rescue*

# Disable network service here, as doing it in the services line
# fails due to RHBZ #1369794
/sbin/chkconfig network off

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

#    && curl -OL https://www2.ati.com/drivers/linux-amd-14.41rc1-opencl2-sep19.zip -e http://support.amd.com/en-us/kb-articles/Pages/OpenCL2-Driver.aspx \
#    && curl -OL https://www2.ati.com/drivers/linux/rhel7/amdgpu-pro-17.50-511655.tar.xz -e http://support.amd.com/en-us/kb-articles/Pages/Installation-Instructions-for-amdgpu-Graphics-Stacks.aspx \
#    && curl -OL https://github.com/curl/curl/releases/download/curl-7_57_0/curl-7.57.0.tar.gz \

echo 'Fedora release 27 (Twenty Seven)' > /etc/redhat-release

mkdir -p /opt/bin /opt/miners /tmp/build \
    && cd /tmp/build \
    && echo "nameserver    8.8.8.8" >> /etc/resolv.conf \
    && curl -OL http://github.com/ethereum-mining/ethminer/releases/download/v0.12.0/ethminer-0.12.0-Linux.tar.gz \
    && curl -OL http://github.com/sgminer-dev/sgminer/archive/5.1.1.tar.gz \
    && curl -OL http://github.com/ckolivas/cgminer/archive/v4.10.0.tar.gz \
    && curl -OL http://github.com/nanopool/Claymore-Dual-Miner/releases/download/v10.0/Claymore.s.Dual.Ethereum.Decred_Siacoin_Lbry_Pascal.AMD.NVIDIA.GPU.Miner.v10.0.-.LINUX.tar.gz \
    && mkdir -p Claymore \
    && tar -xzf Claymore.s.Dual.Ethereum.Decred_Siacoin_Lbry_Pascal.AMD.NVIDIA.GPU.Miner.v10.0.-.LINUX.tar.gz -C Claymore \
    && mv Claymore /opt/miners \
    && rm Claymore.s.Dual.Ethereum.Decred_Siacoin_Lbry_Pascal.AMD.NVIDIA.GPU.Miner.v10.0.-.LINUX.tar.gz 
#cd /tmp/build && \
#    unzip linux-amd-14.41rc1-opencl2-sep19.zip \
#    && cd fglrx-14.41 \
#    && sh amd-driver-installer-14.41-x86.x86_64.run && cd - 
dnf clean packages
cd /tmp/build \
    && tar -xzf ethminer-0.12.0-Linux.tar.gz \
    && mv bin/* /opt/bin
#cd /tmp/build \
#    && tar -Jxvf amdgpu-pro-17.50-511655.tar.xz \
#    && cd amdgpu-pro-17.50-511655 \
#    && ./amdgpu-install -y


cat > /opt/bin/claymore.sh <<EOF
#!/bin/sh

export GPU_FORCE_64BIT_PTR=1
export GPU_MAX_HEAP_SIZE=100
export GPU_USE_SYNC_OBJECTS=1
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100
export LD_LIBRARY_PATH=/opt/lib

cd /opt/miners/Claymore

exec ./ethdcrminer64 -epool \$1 -ewal \$2 -epsw x -mode 1 -ftime 10
EOF

# Setup Claymore process
/usr/sbin/useradd -M claymore -G wheel -s /sbin/nologin
chmod 755 /opt/bin/claymore.sh

#cat > /etc/systemd/system/claymore <<EOF
#[Unit]
#escription=Claymore Service
#After=multi-user.target

#[Service]
#Type=simple
#User=claymore
#ExecStart=/opt/bin/claymore.sh 
#Restart=on-abort
#StandardOutput=journal
#StandardError=journal

#[Install]
#WantedBy=multi-user.target
#EOF

# Setup Ethminer process
/usr/sbin/useradd -M ethminer -G wheel -s /sbin/nologin

cat > /etc/systemd/system/ethminer.service <<EOF
[Unit]
Description=Ethminer Service
Requires=network.target
After=multi-user.target

[Service]
Type=simple
User=ethminer
WorkingDirectory=/
PermissionsStartOnly=true
ExecStart=/opt/bin/ethminer --farm-recheck 10000 -S 
ExecReload=/bin/kill -HUP
ExecStop=/bin/kill -15
Restart=on-failure
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

#systemctl enable claymore
systemctl enable ethminer

%end


%post --nochroot
cp $INSTALL_ROOT/usr/share/licenses/*-release/* $LIVE_ROOT/

# only works on x86, x86_64
if [ "$(uname -i)" = "i386" -o "$(uname -i)" = "x86_64" ]; then
  if [ ! -d $LIVE_ROOT/LiveOS ]; then mkdir -p $LIVE_ROOT/LiveOS ; fi
  cp /usr/bin/livecd-iso-to-disk $LIVE_ROOT/LiveOS
fi

%end