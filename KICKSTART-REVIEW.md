# Pendo Linux 2.0 - Kickstart review (what was wrong, what changed)

Original `pendo-linux-2.0-ks.cfg` passed `ksvalidator` (syntax only). The problems below are
the ones that would have broken the build, the installed system, or the project brief.
Nothing here has been built into an ISO. Verified so far: kickstart syntax (pykickstart 3.78,
F44), shellcheck/bash -n on all scripts, flatten of the include chain with a stub base,
GVariant/XML syntax of the config files, the %pre disk-safety logic and the Dash to Dock
version check. NOT verified: package names against live Fedora repos, the RPM build,
the ISO build, boot, install, OOBE, SELinux behaviour.

## Build breakers
| # | Original | Problem | Fix |
|---|---|---|---|
| 1 | `--releasever 41` (scripts/docs) | Fedora 41 is end-of-life. Fedora 45 shipped 2026-11-03; 44 is the stable choice for GNOME 50 | Target F44, one variable `PENDO_FEDORA` |
| 2 | One ks used for `livemedia-creator` with LVM, swap, `clearpart`, `firstboot` | A live ISO is built from a live-style ks (dracut-live, livesys, squashfs layout). An installer-style ks does not produce a bootable live ISO | Split: `pendo-live.ks` (includes Fedora's `fedora-live-workstation.ks`) + `pendo-install.ks` + shared `pendo-payload.ks` |
| 3 | `gnome-shell-extension-dash-to-panel` | Brief requires **Dash to Dock** | `gnome-shell-extension-dash-to-dock`, UUID `dash-to-dock@micxgx.gmail.com`, schema keys updated; %post fails the build if its metadata does not list the shipped GNOME Shell major version |
| 4 | `geogebra`, `vlc`, `epoptes-client`, `code-server`, `pam_krb5`, `evince`, `clamd`, `gnome-power-manager`, `curl` | Not in Fedora repos (GeoGebra/VLC/Epoptes/code-server), retired/superseded, or conflicts (`curl` vs `curl-minimal`) -> dnf transaction fails | Removed. GeoGebra and Scratch install as Flatpaks via first-boot unit |
| 5 | `tlp` | Conflicts with Fedora's power-profiles stack, pulled in by GNOME -> dependency error | Removed |
| 6 | `systemctl enable epoptes-client / tlp / realmd / sssd ...` under `%post --erroronfail` | Missing or no-[Install] units abort the whole build | Only units that exist are enabled |
| 7 | `flatpak remote-add`, `flatpak install`, `flatpak override`, `curl` wallpaper/watermark, `freshclam` in %post | No network/D-Bus/bwrap in the build chroot; `YOUR_ORG` URL placeholders | All removed; first-boot `pendo-flatpak-apps.service` does it when online |
| 8 | Python/PIL gradient fallback wallpaper | PIL not installed -> abort; also generated artwork (brief forbids) and purple/orange | Wallpaper ships in RPM `pendo-defaults` from your supplied file |
| 9 | `--resultdir` pre-created by script | livemedia-creator refuses an existing resultdir | Timestamped, not-yet-existing dir |
| 10 | `livemedia-creator ... \| tee` then `if [ $? ]` | `$?` is tee's status; failures were reported as success | Script uses `set -euo pipefail` |
| 11 | `dnf install anaconda-tui pungi genisoimage` | Wrong/unneeded; the no-virt tool is `lorax-lmc-novirt` | `build-iso.sh` lists correct packages and checks host release == target |

## Installed-system bugs (would not error at build but would be wrong at runtime)
- **No EFI partition**: `bootloader --location=mbr` + `/boot` only -> UEFI install fails. Now `reqpart`.
- **`clearpart --all` with no drive**: erased every disk silently. Now install aborts in `%pre`
  unless BOTH `pendo.disk=<dev>` and `pendo.erase=YES` are on the boot line; device name validated.
- VG named `fedora` clashes with an existing Fedora install -> `pendo_vg`. Fixed 4 GB swap LV dropped (Fedora uses zram).
- `lock-delay=30` etc. need `uint32` in dconf or are ignored. Fixed.
- Wallpaper path pointed at a `.png` that was never created. Now `.webp` installed by the RPM.
- gnome-initial-setup: wrong path (`/etc/...`), invented keys (`welcome=`, `[account]`, `[welcome] title=`). The only real key is `skip=`; now `/usr/share/gnome-initial-setup/vendor.conf` with `skip=software;goa` (privacy page kept per brief). Welcome text cannot be changed this way: needs a custom OOBE later.
- `systemctl enable gnome-initial-setup-first-login.service` and `rm .../done` removed; `firstboot --enable` is the supported trigger.
- `/etc/cron.weekly`, `/etc/cron.daily`: cronie is not in Workstation, jobs never ran. Replaced by systemd timers.
- Weekly `clamscan /` -> `/home` only, niced, with DB-exists condition. Backup `rsync --delete` removed (an empty/unmounted /home would wipe the backup); `ConditionPathExists` on its config.
- `/etc/pip/pip.conf` is not read by pip, and `user = true` breaks venvs -> removed.
- `npm config set prefix` ran as root in the chroot -> `NPM_CONFIG_PREFIX` in profile.d.
- `/etc/git/config` is not read by git -> `/etc/gitconfig`.
- Flatpak "restrictions" **granted** every app Documents+Downloads access (default is none) -> removed.
- `--ntpservers` deprecated -> `timesource --ntp-pool`. `authselect select sssd` at install with no domain -> now enables only `with-faillock` on the default profile (`realm join` replaces the profile; re-enable faillock after joining).
- Duplicate `wine.desktop`/mimeapps override of the package's own handlers removed.

## Decisions for you (brief vs. original file)
1. **Open ports**: original opened ssh + 631 (CUPS) on every machine. Brief says no unnecessary services. Now no extra ports; sshd installed, not enabled.
2. **USBGuard**: original enabled a rule set that would block printers, webcams, Bluetooth and USB content packs (offline-first feature). Now installed but disabled; a safer example is in `/usr/share/pendo/usbguard-lab-example.conf`.
3. **Wine auto-run of .exe** and the heavy apps (blender, octave, maxima, gnucash) are commented out. Wine contradicts the security goals; the others inflate the ISO. Measure, then uncomment.
4. **Automatic security updates** (dnf-automatic) removed: DNF5 changed units/config, Fedora has no reliable "security-only" mode, and the brief wants a controlled stable/testing process.
5. **Epoptes (classroom control)** has no Fedora package; needs an alternative or a Pendo-built RPM.
6. **Branding assets**: `Vector.svg` is the **ZORIN** wordmark - a third-party trademark; it is not included. `pendo-logo-zorin-style.svg` is renamed `pendo-logo.svg` (rename suggests imitation; the penguin is Tux, fine). The wallpaper is 960x720 (4:3) and purple/orange, while the brief specifies blue/cyan/navy and 1080p+; it will look soft on modern screens. I used it unchanged.

## Risks I could not check from here
Fedora repos were unreachable from my sandbox, so package names are from knowledge: run
`build/preflight.sh` on the Fedora 44 VM first; it reports every missing package.
Least certain: `audacity`, `tuxtype`, `iotop`, `timeshift`, `kalzium`, `cups-filters`, Flathub IDs
`org.geogebra.GeoGebra` / `edu.mit.Scratch`, desktop IDs in `favorite-apps`, and whether
Fedora's `fedora-live-workstation.ks` leaves enough root size for this package set (check the
`part /` line in the flattened ks if the build runs out of space). SELinux: the clamscan unit
and flatpak unit must be tested in enforcing mode (check `ausearch -m avc`).

## Order to run (inside a disposable Fedora 44 VM)
    sudo dnf install lorax-lmc-novirt pykickstart git rpm-build createrepo_c 
    build/preflight.sh                       # no root
    sudo PENDO_CONFIRM=yes build/build-iso.sh
