#!/bin/bash
# Builds the live ISO. Run as root INSIDE a disposable Fedora VM whose release
# equals PENDO_FEDORA (livemedia-creator --no-virt uses the host's anaconda).
# Never run this on your everyday machine.
set -euo pipefail
. "$(dirname "$0")/common.sh"
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "===== livemedia log tail ====="; tail -n 200 "$ROOT"/build/logs/livemedia-*.log 2>/dev/null || true; echo "===== root password / chpasswd references ====="; grep -Rni "chpasswd\|rootpw\|locked" "$ROOT"/build/logs/anaconda 2>/dev/null || true; for f in /tmp/anaconda.log /tmp/packaging.log /tmp/program.log /tmp/storage.log /var/log/anaconda/*.log "$ROOT"/build/logs/anaconda/*.log; do if [ -f "$f" ]; then echo "===== $f ====="; tail -n 500 "$f"; fi; done; fi; exit $rc' EXIT

[ "$(id -u)" -eq 0 ] || { echo "Run as root in the build VM: sudo $0"; exit 1; }
. /etc/os-release
[ "${ID:-}" = fedora ] && [ "${VERSION_ID:-}" = "$PENDO_FEDORA" ] || {
  echo "Build host is ${PRETTY_NAME:-unknown}; must be Fedora $PENDO_FEDORA (set PENDO_FEDORA to match)."; exit 1; }
for c in livemedia-creator ksflatten ksvalidator git rpmbuild createrepo_c; do
  command -v "$c" >/dev/null || { echo "Missing: $c. Install: dnf install lorax-lmc-novirt pykickstart git rpm-build createrepo_c"; exit 1; }
done
[ "${PENDO_CONFIRM:-}" = yes ] || { echo "This installs a system inside loop devices on this host. Re-run with PENDO_CONFIRM=yes inside the build VM."; exit 1; }

"$ROOT/build/preflight.sh"
"$ROOT/build/build-rpm.sh"

KS="$WORK/ks"; rm -rf "$KS"; mkdir -p "$KS"
KS_URL="https://forge.fedoraproject.org/releng/spin-kickstarts.git"
KS_BRANCH="f$PENDO_FEDORA"
if ! git ls-remote --heads "$KS_URL" "refs/heads/$KS_BRANCH" | grep -q .; then
  echo "No kickstart branch $KS_BRANCH; falling back to f43 (last kickstart-based Fedora branch)"
  KS_BRANCH="f43"
fi
git clone --branch "$KS_BRANCH" "$KS_URL" "$KS/upstream"
cp "$KS"/upstream/*.ks "$KS"/
# Fedora's live-workstation kickstart redefines the root partition that
# fedora-live-base.ks already defines. Increase the workstation root size to 12288 MiB
# and make the filesystem type explicit.
sed -i -E '/^[[:space:]]*part[[:space:]]+\/[[:space:]]/d' "$KS/fedora-live-base.ks"
sed -i -E 's/^rootpw --lock --iscrypted locked$/rootpw --lock/' "$KS/fedora-live-base.ks"
sed -i -E 's/^(part[[:space:]]+\/[[:space:]]+--size)[[:space:]]+8576[[:space:]]*$/\1 12288 --fstype ext4/' "$KS/fedora-live-workstation.ks"
cp "$KSDIR"/pendo-live.ks "$KSDIR"/pendo-payload.ks "$KSDIR"/pendo-repo.ks "$KS"/
( cd "$KS" && ksflatten -v "F$PENDO_FEDORA" -c pendo-live.ks -o flat-pendo-live.ks && ksvalidator -v "F$PENDO_FEDORA" flat-pendo-live.ks )

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$ROOT/build/out/$STAMP"          # livemedia-creator requires that this does NOT exist yet
mkdir -p "$ROOT/build/out" "$ROOT/build/logs" "$WORK/tmp"
livemedia-creator \
  --ks "$KS/flat-pendo-live.ks" \
  --no-virt --make-iso --iso-only \
  --project "Pendo Linux" --releasever "$PENDO_FEDORA" \
  --volid "Pendo-2.0-x86_64" --iso-name "pendo-linux-2.0-x86_64.iso" \
  --resultdir "$OUT" --tmp "$WORK/tmp" \
  --logfile "$ROOT/build/logs/livemedia-$STAMP.log"

( cd "$OUT" && sha256sum pendo-linux-2.0-x86_64.iso | tee pendo-linux-2.0-x86_64.iso.sha256 )
echo "ISO: $OUT/pendo-linux-2.0-x86_64.iso  (untested until booted in QEMU/KVM)"
