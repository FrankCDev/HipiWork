#!/bin/sh
# HipiWork installer
#
# Downloads a prebuilt HipiWork release archive and puts `hipi` on your PATH.
# No Node, npm, Bun, or compiler toolchain is required: the archive contains a
# self-contained executable plus the assets it loads at runtime.
#
#   curl -fsSL https://raw.githubusercontent.com/FrankCDev/HipiWork/hipi-dev/scripts/install.sh | sh
#
# Flags (each also settable as an environment variable):
#   --version <x.y.z>     install a specific version     (HIPI_VERSION; default: latest release)
#   --install-dir <dir>   where the payload is unpacked  (HIPI_INSTALL_DIR; default: ~/.local/share/hipi)
#   --bin-dir <dir>       where the `hipi` command lives (HIPI_BIN_DIR; default: ~/.local/bin)
#   -h | --help
#
# Windows is not handled here. Use hipi-windows-<arch>.zip from the same release
# and put hipi.exe somewhere on your PATH yourself.
#
# Mirrors / air-gapped installs: point HIPI_RELEASE_BASE_URL at a directory that
# mirrors the release assets (a file:// URL works) and pass --version explicitly,
# because "latest" is resolved through the GitHub releases page.

set -eu

REPO="https://github.com/FrankCDev/HipiWork"
BINARY_NAME="hipi"

say() { printf 'hipi-install: %s\n' "$*"; }
warn() { printf 'hipi-install: warning: %s\n' "$*" >&2; }
die() { printf 'hipi-install: error: %s\n' "$*" >&2; exit 1; }

usage() {
	cat <<'EOF'
Install HipiWork from a prebuilt release archive.

Usage: install.sh [options]

Options:
  --version <x.y.z>     Version to install. Default: the latest release.
  --install-dir <dir>   Directory the payload is unpacked into.
                        Default: $XDG_DATA_HOME/hipi, else ~/.local/share/hipi
  --bin-dir <dir>       Directory the `hipi` command is written to.
                        Default: ~/.local/bin
  -h, --help            Show this message.

Environment:
  HIPI_VERSION            Same as --version.
  HIPI_INSTALL_DIR        Same as --install-dir.
  HIPI_BIN_DIR            Same as --bin-dir.
  HIPI_RELEASE_BASE_URL   Override the asset host, e.g. a mirror or file:// URL.
EOF
}

VERSION="${HIPI_VERSION:-}"
INSTALL_DIR="${HIPI_INSTALL_DIR:-}"

while [ $# -gt 0 ]; do
	case "$1" in
		--version) [ $# -ge 2 ] || die "--version needs a value"; VERSION="$2"; shift 2 ;;
		--version=*) VERSION="${1#*=}"; shift ;;
		--install-dir) [ $# -ge 2 ] || die "--install-dir needs a value"; INSTALL_DIR="$2"; shift 2 ;;
		--install-dir=*) INSTALL_DIR="${1#*=}"; shift ;;
		--bin-dir) [ $# -ge 2 ] || die "--bin-dir needs a value"; HIPI_BIN_DIR="$2"; shift 2 ;;
		--bin-dir=*) HIPI_BIN_DIR="${1#*=}"; shift ;;
		-h | --help) usage; exit 0 ;;
		*) die "unknown argument: $1 (try --help)" ;;
	esac
done

# --- preflight -------------------------------------------------------------

if command -v curl >/dev/null 2>&1; then
	fetch() { curl -fsSL --retry 3 --retry-delay 1 -o "$2" "$1"; }
elif command -v wget >/dev/null 2>&1; then
	fetch() { wget -q -O "$2" "$1"; }
else
	die "either curl or wget is required"
fi

command -v tar >/dev/null 2>&1 || die "tar is required"

if command -v sha256sum >/dev/null 2>&1; then
	sha256_of() { sha256sum "$1" | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
	sha256_of() { shasum -a 256 "$1" | awk '{print $1}'; }
else
	die "sha256sum or shasum is required to verify the download"
fi

# --- platform --------------------------------------------------------------

uname_s=$(uname -s)
uname_m=$(uname -m)

case "$uname_s" in
	Darwin) OS=darwin ;;
	Linux) OS=linux ;;
	MINGW* | MSYS* | CYGWIN*) die "this script is POSIX-only; on Windows download hipi-windows-x64.zip from the release page" ;;
	*) die "unsupported operating system: $uname_s" ;;
esac

# An x86_64 shell on Apple Silicon reports x86_64. Prefer the native arm64 build.
if [ "$OS" = darwin ] && [ "$uname_m" = x86_64 ]; then
	if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = "1" ]; then
		uname_m=arm64
	fi
fi

case "$uname_m" in
	x86_64 | amd64) ARCH=x64 ;;
	arm64 | aarch64) ARCH=arm64 ;;
	*) die "unsupported architecture: $uname_m" ;;
esac

PLATFORM="${OS}-${ARCH}"
case "$PLATFORM" in
	darwin-arm64 | darwin-x64 | linux-x64 | linux-arm64) ;;
	*) die "no prebuilt binary for $PLATFORM" ;;
esac

# --- version ---------------------------------------------------------------

if [ -z "$VERSION" ]; then
	say "resolving the latest release..."
	effective=$(curl -fsSL -o /dev/null -w '%{url_effective}' "$REPO/releases/latest" 2>/dev/null || true)
	case "$effective" in
		*/tag/*) VERSION="${effective##*/tag/}" ;;
		*) die "could not resolve the latest version from $REPO/releases/latest; pass --version" ;;
	esac
fi
VERSION="${VERSION#v}"
[ -n "$VERSION" ] || die "empty version"

ASSET="${BINARY_NAME}-${PLATFORM}.tar.gz"
BASE_URL="${HIPI_RELEASE_BASE_URL:-$REPO/releases/download}"
ASSET_URL="${BASE_URL}/v${VERSION}/${ASSET}"
SUMS_URL="${BASE_URL}/v${VERSION}/SHA256SUMS"

# --- download and verify ---------------------------------------------------

TMP="$(mktemp -d "${TMPDIR:-/tmp}/hipi-install.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT INT TERM

say "downloading $ASSET (v$VERSION)..."
fetch "$ASSET_URL" "$TMP/$ASSET" || die "download failed: $ASSET_URL"
fetch "$SUMS_URL" "$TMP/SHA256SUMS" || die "download failed: $SUMS_URL"

expected=$(awk -v f="$ASSET" '$2 == f || $2 == "*" f { print $1; exit }' "$TMP/SHA256SUMS")
[ -n "$expected" ] || die "SHA256SUMS does not list $ASSET; refusing to install an unverified archive"

actual=$(sha256_of "$TMP/$ASSET")
[ "$expected" = "$actual" ] || die "checksum mismatch for $ASSET
  expected $expected
  actual   $actual"
say "sha256 verified"

# --- unpack ----------------------------------------------------------------

mkdir -p "$TMP/unpack"
tar -xzf "$TMP/$ASSET" -C "$TMP/unpack" || die "could not extract $ASSET"

# The unix archives carry a single wrapper directory named after the binary
# (kept for mise compatibility); the layout is stable, but do not assume it.
SRC="$TMP/unpack/$BINARY_NAME"
[ -f "$SRC/$BINARY_NAME" ] || die "unexpected archive layout: $BINARY_NAME/$BINARY_NAME is missing"
# Keep package.json: the running binary reads pkg.name/pkg.version from it.

# --- install ---------------------------------------------------------------

[ -n "$INSTALL_DIR" ] || INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/$BINARY_NAME"
case "$INSTALL_DIR" in
	/*) ;;
	*) die "--install-dir must be an absolute path (got: $INSTALL_DIR)" ;;
esac
[ "$INSTALL_DIR" != "/" ] || die "refusing to install into /"

BIN_DIR="${HIPI_BIN_DIR:-$HOME/.local/bin}"
case "$BIN_DIR" in
	/*) ;;
	*) die "--bin-dir must be an absolute path (got: $BIN_DIR)" ;;
esac

STAGE="${INSTALL_DIR}.new.$$"
OLD="${INSTALL_DIR}.old.$$"

mkdir -p "$(dirname "$INSTALL_DIR")"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$SRC/." "$STAGE/"
chmod 755 "$STAGE/$BINARY_NAME"

# Swap in the new payload so an upgrade cannot leave files from the old version
# behind. The old copy is removed only after the move succeeds.
if [ -e "$INSTALL_DIR" ]; then mv "$INSTALL_DIR" "$OLD"; fi
mv "$STAGE" "$INSTALL_DIR"
rm -rf "$OLD"

# macOS: drop the quarantine flag so Gatekeeper does not refuse an unsigned
# binary. curl does not set it, but browsers and archive tools can. BSD xattr has
# no recursive mode, and it reports errors on stdout, so drive it per file.
if [ "$OS" = darwin ] && command -v xattr >/dev/null 2>&1; then
	find "$INSTALL_DIR" -exec xattr -c {} + >/dev/null 2>&1 || true
fi

# A wrapper rather than a symlink: the binary locates its assets through
# dirname(process.execPath), and exec'ing the real path keeps that unambiguous
# on every platform instead of relying on symlink resolution.
mkdir -p "$BIN_DIR"
cat >"$BIN_DIR/$BINARY_NAME" <<EOF
#!/bin/sh
# Generated by the HipiWork installer; reinstall to update.
exec "$INSTALL_DIR/$BINARY_NAME" "\$@"
EOF
chmod 755 "$BIN_DIR/$BINARY_NAME"

# --- report ----------------------------------------------------------------

if installed_version=$("$INSTALL_DIR/$BINARY_NAME" --version 2>/dev/null); then
	say "installed $BINARY_NAME $installed_version"
else
	warn "installed, but '$BINARY_NAME --version' did not run; check the output above"
fi
say "payload: $INSTALL_DIR"
say "command: $BIN_DIR/$BINARY_NAME"

case ":${PATH:-}:" in
	*":$BIN_DIR:"*) ;;
	*)
		say ""
		say "$BIN_DIR is not on your PATH. Add it to your shell profile:"
		printf '  export PATH="%s:$PATH"\n' "$BIN_DIR"
		;;
esac
