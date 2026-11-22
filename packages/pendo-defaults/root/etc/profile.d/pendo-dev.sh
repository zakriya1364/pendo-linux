# Global npm installs go to the user's home instead of /usr (needs no root).
export NPM_CONFIG_PREFIX="${NPM_CONFIG_PREFIX:-$HOME/.local}"
