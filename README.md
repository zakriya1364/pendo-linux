# Pendo Linux 2.0

Fedora 44 (GNOME 50) based educational lab distribution.

## Build

Inside a disposable Fedora 44 VM:

```sh
sudo dnf install lorax-lmc-novirt pykickstart git rpm-build createrepo_c
./build/preflight.sh
sudo PENDO_CONFIRM=yes ./build/build-iso.sh
```

The ISO is written to `build/out/<timestamp>/pendo-linux-2.0-x86_64.iso`.

## Validation performed in this environment

- `bash -n` on all shell scripts (pass).
- `dconf compile` on `01-pendo-desktop` (pass).
- `xmllint` on `pendo-wallpapers.xml` (pass).
- `systemd-analyze verify` on unit files (pass; only missing-binary warnings for clamscan/flatpak helpers, expected on a non-Pendo host).
- Kickstart include chain inspected manually (pykickstart unavailable here).

## Not verified (requires Fedora host / VM)

- `ksvalidator` / `ksflatten` syntax validation.
- Package availability against Fedora 44 repos (run `build/preflight.sh` on Fedora).
- RPM build and ISO build.
- Boot, install, OOBE, SELinux behaviour (user performs VM testing).

See `KICKSTART-REVIEW.md` for the full review of fixes and risks.