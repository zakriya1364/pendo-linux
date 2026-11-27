# =====================================================================
# PENDO LINUX 2.0 - SHARED PAYLOAD  (packages + post-install only)
# =====================================================================
# Included by pendo-live.ks (ISO build) and pendo-install.ks (lab install).
# Contains ONLY %packages and %post: installer commands (lang, selinux,
# firewall, partitioning ...) live in the including file so that nothing is
# defined twice after Fedora's own kickstarts are flattened in.
# Target: Fedora 44 (GNOME 50). Check names with build/preflight.sh.
# =====================================================================

%packages
# --- Desktop -----------------------------------------------------------
gnome-shell-extension-dash-to-dock
gnome-tweaks
gnome-initial-setup
firefox

# --- Hardware support (kernel itself comes from the base environment) --
linux-firmware
kernel-modules-extra
NetworkManager-wifi
usb_modeswitch

# --- Enterprise sign-in (AD / FreeIPA); inactive until a domain is joined
realmd
sssd
sssd-ad
sssd-ipa
freeipa-client
adcli
oddjob
oddjob-mkhomedir
samba-common-tools
chrony
# sshd is installed but NOT enabled (see %post)
openssh-server

# --- Educational software ----------------------------------------------
libreoffice-writer
libreoffice-calc
libreoffice-impress
libreoffice-math
gcompris-qt
stellarium
kalzium
tuxmath
# tuxtype: provided as an optional Flatpak (com.tux4kids.tuxtype)
# via pendo-flatpak-apps.service on first boot; not in the mandatory ISO set.
klavaro
krita
gimp
inkscape
audacity

# --- Printing ------------------------------------------------------------
cups
cups-filters
gutenprint
hplip
system-config-printer

# --- Accessibility -------------------------------------------------------
orca

# --- Endpoint security -----------------------------------------------------
clamav
clamav-freshclam
# installed for lab admins; NOT enabled (can block printers/webcams/USB packs)
usbguard

# --- Backup / sync ---------------------------------------------------------
timeshift
rsync
rclone

# --- Monitoring --------------------------------------------------------------
htop
iotop
gnome-system-monitor
powertop

# --- Computer-science tools ----------------------------------------------------
git
python3
python3-pip
gcc
make
nodejs
npm

# --- Docs / misc -----------------------------------------------------------------
gnome-user-docs
flatpak
dconf
jq

# --- Pendo's own configuration package (built by build/build-rpm.sh) -------------
pendo-defaults

# --- Removals ---------------------------------------------------------------------
-gnome-tour

# ---------------------------------------------------------------------------------
# OPTIONAL / HEAVY - deliberately NOT in the default ISO (size, security).
# Uncomment only after measuring ISO size and deciding on the security impact.
# blender
# octave
# maxima
# gnucash
# wine          # lets students run unknown .exe files: weigh against school policy
# ---------------------------------------------------------------------------------
%end

%post --erroronfail --log=/root/pendo-payload-post.log
set -eu

# 1. SELinux must be enforcing; fail the build rather than ship otherwise.
if ! grep -q '^SELINUX=enforcing' /etc/selinux/config; then
    echo "FATAL: /etc/selinux/config is not SELINUX=enforcing" >&2
    exit 1
fi

# 2. dconf: make sure the 'local' system database is part of the user profile.
mkdir -p /etc/dconf/profile
if ! grep -qs '^system-db:local$' /etc/dconf/profile/user; then
    printf 'user-db:user\nsystem-db:local\n' > /etc/dconf/profile/user
fi
dconf update

# 3. First-boot wizard: apply Pendo's page list (only supported key is 'skip').
install -D -m 0644 /usr/share/pendo/gnome-initial-setup-vendor.conf \
    /usr/share/gnome-initial-setup/vendor.conf

# 4. Dash to Dock must declare support for the GNOME Shell version we ship.
EXT=/usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/metadata.json
if [ ! -f "$EXT" ]; then
    echo "FATAL: Dash to Dock not found at $EXT" >&2
    exit 1
fi
SHELL_MAJOR=$(rpm -q --qf '%{VERSION}' gnome-shell | cut -d. -f1)
python3 - "$EXT" "$SHELL_MAJOR" <<'PY'
import json, sys
meta = json.load(open(sys.argv[1]))
major = sys.argv[2]
versions = [str(v) for v in meta.get("shell-version", [])]
if not any(v == major or v.startswith(major + ".") for v in versions):
    sys.exit("FATAL: Dash to Dock supports GNOME Shell %s, not %s" % (versions, major))
print("Dash to Dock supports GNOME Shell", major)
PY

# 5. Account lockout after repeated failed logins (best effort; realm join
#    re-selects the authselect profile and must re-enable this feature).
authselect current >/dev/null 2>&1 || authselect select local with-silent-lastlog --force
if ! authselect current --raw | grep -qw with-faillock; then
    authselect enable-feature with-faillock || echo "WARNING: could not enable with-faillock" >&2
fi

# 6. Services. sshd and usbguard are intentionally left disabled.
systemctl enable chronyd.service
systemctl enable cups.service
systemctl enable clamav-freshclam.service
systemctl enable pendo-clamscan.timer
systemctl enable pendo-home-backup.timer
systemctl enable pendo-flatpak-apps.service
%end
