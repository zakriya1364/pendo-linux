# Shared settings. Override from the environment, e.g.  PENDO_FEDORA=45 ./build-iso.sh
PENDO_FEDORA="${PENDO_FEDORA:-44}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KSDIR="$ROOT/installer/kickstart"
WORK="$ROOT/build/work"
