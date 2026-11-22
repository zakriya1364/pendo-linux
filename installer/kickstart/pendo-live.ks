# =====================================================================
# PENDO LINUX 2.0 - LIVE ISO KICKSTART
# =====================================================================
# Not usable on its own: build/build-iso.sh copies Fedora's
# fedora-kickstarts (matching release branch) next to this file and runs
# `ksflatten`, then livemedia-creator builds the ISO from the flat result.
#
# Everything that makes the live image bootable (partition layout, dracut-live,
# livesys, repos, SELinux, firewalld, boot loader) comes from Fedora's file.
# The user is created later by Anaconda / gnome-initial-setup: no accounts or
# passwords are defined here.
# =====================================================================
%include fedora-live-workstation.ks
%include pendo-repo.ks
%include pendo-payload.ks
