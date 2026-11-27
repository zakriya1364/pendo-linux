Name:           pendo-defaults
Version:        2.0
Release:        1%{?dist}
Summary:        Pendo Linux branding, GNOME defaults and helper services
License:        LicenseRef-Pendo
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz

Requires:       dconf
Requires:       gnome-shell-extension-dash-to-dock
Requires:       rsync
Requires:       flatpak
BuildRequires:  systemd-rpm-macros

%description
Wallpaper, logo, system-wide dconf defaults (Dash to Dock, wallpaper, media
handling, idle/lock), gnome-initial-setup vendor config, systemd units for
optional backup/scan/Flatpak setup, and small administration helpers.

%prep
%autosetup -n %{name}-%{version}

%build
# nothing to build

%install
mkdir -p %{buildroot}
cp -a root/. %{buildroot}
mkdir -p %{buildroot}/etc/skel/Portfolio/Code \
         %{buildroot}/etc/skel/Portfolio/Media \
         %{buildroot}/etc/skel/Portfolio/Documents
mkdir -p %{buildroot}/etc/pendo
install -D -m 0644 assets/pendo-wallpaper.webp \
    %{buildroot}/usr/share/backgrounds/pendo/pendo-default.webp
install -D -m 0644 assets/pendo-logo.svg \
    %{buildroot}/usr/share/icons/hicolor/scalable/apps/pendo-logo.svg

%posttrans
dconf update || :

%files
%config(noreplace) /etc/dconf/db/local.d/01-pendo-desktop
%config(noreplace) /etc/dconf/db/local.d/locks/01-pendo-locks
%config(noreplace) /etc/ssh/sshd_config.d/10-pendo.conf
%config(noreplace) /etc/gitconfig
/etc/profile.d/pendo-dev.sh
/etc/skel/Portfolio
%dir /etc/pendo
/usr/share/backgrounds/pendo
/usr/share/gnome-background-properties/pendo-wallpapers.xml
/usr/share/icons/hicolor/scalable/apps/pendo-logo.svg
/usr/share/pendo
/usr/share/plymouth/themes/pendo
/usr/libexec/pendo
/usr/share/sounds/pendo
%config(noreplace) /etc/xdg/fastfetch/config.jsonc
/usr/bin/pendo-lab-reset
%{_unitdir}/pendo-*.service
%{_unitdir}/pendo-*.timer

%changelog
* Sun Nov 22 2026 Pendo Linux Team <noreply@example.invalid> - 2.0-1
- Initial package
