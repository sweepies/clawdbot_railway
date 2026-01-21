MISE_TRUSTED_CONFIG_PATHS=/root:/data

eval "$(~/.local/bin/mise activate bash)"

if command -v fnox >/dev/null 2>&1; then
  fnox activate bash | source /dev/stdin
fi