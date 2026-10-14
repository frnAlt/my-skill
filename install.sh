#!/usr/bin/env bash
# ==============================================================================
# Antigravity Skills & Plugins Installer
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_CONFIG_DIR="${HOME}/.gemini/config"
TARGET_PLUGINS_DIR="${TARGET_CONFIG_DIR}/plugins"
TARGET_SKILLS_DIR="${HOME}/.gemini/skills"

echo "=========================================================="
echo "Installing Antigravity Skills & Plugins from ${SCRIPT_DIR}"
echo "=========================================================="

mkdir -p "${TARGET_PLUGINS_DIR}"
mkdir -p "${TARGET_SKILLS_DIR}"

# 1. Install & Validate Plugins using `agy` if available, or direct copy
if command -v agy >/dev/null 2>&1; then
  echo "Found agy CLI. Installing and validating plugins..."
  for plugin in "${SCRIPT_DIR}/plugins"/*; do
    if [ -d "${plugin}" ]; then
      plugin_name="$(basename "${plugin}")"
      echo "--> Installing plugin: ${plugin_name}"
      agy plugin validate "${plugin}" || true
      agy plugin install "${plugin}" || true
    fi
  done
else
  echo "agy CLI not found in PATH. Copying plugins directly to ${TARGET_PLUGINS_DIR}..."
  for plugin in "${SCRIPT_DIR}/plugins"/*; do
    if [ -d "${plugin}" ]; then
      cp -r "${plugin}" "${TARGET_PLUGINS_DIR}/"
    fi
  done
fi

# 2. Sync Standalone Skills
echo "Syncing standalone skills to ${TARGET_SKILLS_DIR}..."
for skill in "${SCRIPT_DIR}/skills"/*; do
  if [ -d "${skill}" ]; then
    skill_name="$(basename "${skill}")"
    echo "--> Installing skill: ${skill_name}"
    cp -r "${skill}" "${TARGET_SKILLS_DIR}/"
  fi
done

echo ""
echo "=========================================================="
echo "Installation complete!"
if command -v agy >/dev/null 2>&1; then
  echo "Currently installed plugins in Antigravity:"
  agy plugin list || true
fi
echo "=========================================================="
