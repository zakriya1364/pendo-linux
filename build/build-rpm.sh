#!/bin/bash
# Builds pendo-defaults.rpm into a local repo and writes installer/kickstart/pendo-repo.ks.
set -euo pipefail
. "$(dirname "$0")/common.sh"
for c in rpmbuild createrepo_c tar; do command -v "$c" >/dev/null || { echo "Missing: $c (dnf install rpm-build createrepo_c)"; exit 1; }; done
PKG="$ROOT/packages/pendo-defaults"
TOP="$WORK/rpmbuild"; rm -rf "$TOP"; mkdir -p "$TOP"/{SOURCES,SPECS,BUILD,RPMS,SRPMS}
S="$WORK/src/pendo-defaults-2.0"; rm -rf "$WORK/src"; mkdir -p "$S/assets"
cp -a "$PKG/root" "$S/root"
cp "$ROOT/branding/pendo-wallpaper.webp" "$ROOT/branding/pendo-logo.svg" "$S/assets/"
tar -C "$WORK/src" -czf "$TOP/SOURCES/pendo-defaults-2.0.tar.gz" pendo-defaults-2.0
rpmbuild --define "_topdir $TOP" -ba "$PKG/pendo-defaults.spec"
REPO="$ROOT/build/repo"; rm -rf "$REPO"; mkdir -p "$REPO"
cp "$TOP"/RPMS/noarch/pendo-defaults-*.rpm "$REPO/"
createrepo_c "$REPO"
printf 'repo --name=pendo --baseurl=file://%s --cost=50\n' "$REPO" > "$KSDIR/pendo-repo.ks"
echo "Local repo ready: $REPO"
