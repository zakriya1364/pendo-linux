# Pendo Linux 2.1 — Corrected Preparation Report

*Audit corrections replacing inaccurate completion claims with accurate statuses.*

## Preflight
- **Status**: Not executed
- **Environment**: Script documented and ready to run on Fedora 44 container; cannot execute in current CachyOS environment (not Fedora 44)
- **GitHub API**: Returns 404 (no releases published yet for pendo-linux repo) — expected for prototype

## GitHub Actions
- **Status**: Enhancement pending
- **Workflow**: `build-iso` job removed entirely; only `preflight` job remains running `build/preflight.sh` in `fedora:44` container
- **Note**: Preflight-only; no ISO building

## Plymouth
- **Status**: Draft untested
- **Theme**: `pendo.plywood` corrected (ModuleName=script, ImageDir=/usr/share/plymouth/themes/pendo, ScriptFile=/usr/share/plymouth/themes/pendo/pendo.script, BackgroundColour=0.043,0.122,0.227)
- **Script**: Rewritten with HandleCallback dispatcher using Plymouth pymui API; no bare automatic initialise()/render()/finalise() calls
- **Logo**: `logo.png` created from approved branding asset (150x150 PNG, #0b1f3a background)
- **Verification**: Cannot verify boot-time behaviour without Fedora 44 hardware (per restrictions)

## Educational
- **Status**: Proposals only
- **Features**: Exam Mode, Learning Hub, Maintenance Centre deferred to 2.2
- **Note**: No implementation in 2.1 scope

## UEFI
- **Status**: Inspected pending
- **Kickstart**: Existing `pendo-install.ks` uses `reqpart`, `bootloader --location=mbr --boot-drive=$DISK`; no rewrite needed
- **Note**: MBR style partitioning preserved

## Fastfetch
- **Status**: Config inspected pending
- **Configuration**: `config.jsonc` verified (valid JSONC, fastfetch schema, logo.source=/usr/share/pendo/logo/pendo-ansi.txt, padding.right=2)
- **Art**: `pendo-ansi.txt` confirmed (31 lines, ANSI sequences preserved)
- **Spec**: `%config(noreplace) /etc/xdg/fastfetch/config.jsonc` in spec; `fastfetch` in kickstart %packages
- **Note**: Rendering verification pending on fresh Fedora 44 install

## Audio
- **Status**: 5 sound files NOT APPROVED FOR ISO REDISTRIBUTION
- **MP3 files**: `systemcrash-error.mp3`, `universfield-system-notification-02.mp3`, `pendolinuxerror.mp3` (origin unknown; licence unverified)
- **OGG files**: `dialog-error.oga`, `dialog-warning.oga` (converted from MP3s; licence unchanged)
- **Note**: All marked NOT APPROVED; no integration into ISO or system without licence clearance

## DNF5 Repository
- **Status**: Placeholder URLs with `enabled=0`
- **Channels**: `pendo-stable` and `pendo-testing` both set to `enabled=0` with placeholder URLs
- **Note**: Cannot enable without real hosting and GPG key verification

## Repository Readiness
- **Branch**: `pendo-2.1-dev` with approved changes; `main` untouched
- **ISO build**: Not performed (per restrictions)
- **All inaccurate completion claims replaced with accurate statuses**
- **Documentation**: README.md and 2.1-README.md created for GitHub repository

---
*This report corrects all inaccurate "completed" claims from earlier drafts. 
No feature is claimed as release-ready without verified hardware testing.
All work performed on separate development branch; main branch preserved.*
