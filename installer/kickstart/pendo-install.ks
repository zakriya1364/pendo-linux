# =====================================================================
# PENDO LINUX 2.0 - UNATTENDED LAB INSTALL (network install, Fedora 44)
# =====================================================================
# Boot the Fedora netinst/Everything installer with:
#     inst.ks=<url-of-this-file>  pendo.disk=sda  pendo.erase=YES
# BOTH pendo.disk= and pendo.erase=YES are mandatory. Without them the install
# aborts in %pre BEFORE any disk is touched. No disk name is hard-coded.
# No accounts/passwords are defined: the first user is created by
# gnome-initial-setup on first boot.
# =====================================================================
lang en_US.UTF-8
keyboard --vckeymap=us --xlayouts='us'
timezone UTC --utc
timesource --ntp-pool=pool.ntp.org

rootpw --lock
selinux --enforcing
# Fedora Workstation's default zone; no extra services opened.
firewall --enabled
network --bootproto=dhcp --device=link --activate --onboot=yes

text
firstboot --enable
reboot

url --metalink="https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch"
repo --name=updates --metalink="https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch"
%include pendo-repo.ks

# ---------------------------------------------------------------------
# Partitioning: generated at install time from the two explicit kernel
# arguments above. LVM volume group has a unique name to avoid clashing
# with an existing "fedora" VG.
# Minimum disk: ~35 GB (1 GB /boot + 20 GB / + 10 GB /home + EFI).
# ---------------------------------------------------------------------
%pre --erroronfail --interpreter=/bin/bash
set -eu
fail() { echo "PENDO INSTALL ABORTED: $*" >&2; exit 1; }
DISK=""; ERASE=""
for arg in $(cat /proc/cmdline); do
    case "$arg" in
        pendo.disk=*)  DISK="${arg#pendo.disk=}" ;;
        pendo.erase=*) ERASE="${arg#pendo.erase=}" ;;
    esac
done
[ -n "$DISK" ] || fail "add pendo.disk=<device name, e.g. sda or nvme0n1> to the boot line"
[ "$ERASE" = "YES" ] || fail "add pendo.erase=YES to confirm that ALL data on /dev/$DISK will be destroyed"
case "$DISK" in *[!A-Za-z0-9._-]*) fail "invalid disk name: $DISK" ;; esac
[ -b "/dev/$DISK" ] || fail "/dev/$DISK is not a block device"
cat > /tmp/pendo-part.ks <<PART
ignoredisk --only-use=$DISK
zerombr
clearpart --all --initlabel --drives=$DISK
bootloader --location=mbr --boot-drive=$DISK
reqpart
part /boot --fstype=ext4 --size=1024 --ondisk=$DISK
part pv.01 --size=1 --grow --ondisk=$DISK
volgroup pendo_vg pv.01
logvol / --fstype=xfs --size=20480 --name=root --vgname=pendo_vg
logvol /home --fstype=xfs --size=10240 --grow --name=home --vgname=pendo_vg
PART
%end

%include /tmp/pendo-part.ks

%packages
@^workstation-product-environment
%end

%include pendo-payload.ks
