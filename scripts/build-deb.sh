#!/usr/bin/env bash
set -euo pipefail

# Unpack zst files before packaging
if [ -f scripts/decompress.sh ]; then
  ./scripts/decompress.sh
fi

# Packaging script for repository -> .deb
# Copies repository into /opt/<package> inside the package by default.

PKG_NAME="${PACKAGE_NAME:-$(basename "$(git rev-parse --show-toplevel)" )}"
# Determine version: prefer tag, fallback to describe
if [[ "${GITHUB_REF:-}" =~ refs/tags/(.+) ]]; then
  VERSION="${BASH_REMATCH[1]}"
else
  if git rev-parse --git-dir >/dev/null 2>&1; then
    VERSION="$(git describe --tags --always --dirty)"
  else
    VERSION="0.0.0"
  fi
fi
ARCH="$(dpkg --print-architecture || echo all)"
OUT_DIR="artifacts"
WORKDIR="$(mktemp -d)"
PKGROOT="${WORKDIR}/${PKG_NAME}-${VERSION}"

install_path="/usr/lib/firmware"

mkdir -p "${PKGROOT}/DEBIAN"
mkdir -p "${PKGROOT}${install_path}"

# Copy repo into package, exclude heavy or CI dirs
rsync -a \
  --exclude='.git' \
  --exclude='.github' \
  --exclude='artifacts' \
  --exclude='scripts' \
  --exclude='node_modules' \
  --exclude='*.zst' \
  ./ "${PKGROOT}${install_path}/"

# Create a basic control file
cat > "${PKGROOT}/DEBIAN/control" <<EOF
Package: ${PKG_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: GitHub Actions <noreply@github.com>
Depends:
Description: ${PKG_NAME} packaged from repository (automated build)
EOF

# Permissions
find "${PKGROOT}" -type d -exec chmod 0755 {} \;
find "${PKGROOT}" -type f -exec chmod 0644 {} \;
# Make obvious scripts executable
find "${PKGROOT}${install_path}" -type f -name "*.sh" -exec chmod 0755 {} \; || true

mkdir -p "${OUT_DIR}"
DEB_NAME="${PKG_NAME}_${VERSION}_${ARCH}.deb"

fakeroot dpkg-deb --build "${PKGROOT}" "${OUT_DIR}/${DEB_NAME}"

echo "Built ${OUT_DIR}/${DEB_NAME}"
rm -rf "${WORKDIR}"
