#!/bin/sh
# ========================================================================
# OPNsense ntopng GeoIP installer
# One-command setup: MaxMind City+Country + ipinfo.io ASN
# Silent updater script: /usr/local/bin/ntopng-updategeo.sh
# You can get free key for https://ipinfo.io/ and https://www.maxmind.com/
# Ipinfo has more and acurate records, but Ntopng does not support it
# Usage with fetch:
# fetch -o - https://raw.githubusercontent.com/YOURUSERNAME/YOURREPO/main/install-ntopng-geoip.sh \
#    | sh -s -- YOUR_MAXMIND_LICENSE_KEY_HERE your_ipinfo_token_here
# Usage with curl:
# curl -fsSL https://raw.githubusercontent.com/YOURUSERNAME/YOURREPO/main/install-ntopng-geoip.sh \
#    | sh -s -- YOUR_MAXMIND_LICENSE_KEY_HERE your_ipinfo_token_here
# ========================================================================
if [ $# -ne 2 ]; then
    echo "Usage: $0 MAXMIND_LICENSE_KEY IPINFO_TOKEN"
    echo "Example:"
    echo "  fetch -o - https://raw.githubusercontent.com/YOURUSER/YOURREPO/main/install-ntopng-geoip.sh | sh -s -- YOUR_MAXMIND_KEY your_ipinfo_token"
    exit 1
fi

MAXMIND_KEY="$1"
IPINFO_TOKEN="$2"

echo "=== Setting up ntopng GeoIP updater ==="

# 1. Create config with your keys
cat << EOF > /usr/local/etc/GeoIP.conf
LicenseKey ${MAXMIND_KEY}
IPINFO_TOKEN ${IPINFO_TOKEN}
EOF

# 2. Create the silent updater script
cat << 'UPDATER' > /usr/local/bin/ntopng-updategeo.sh
#!/bin/sh
# Silent ntopng GeoIP updater - MaxMind City/Country + ipinfo ASN
# No output on success, only critical errors

set -e

GEOIP_DIR="/usr/local/share/ntopng/httpdocs/geoip"
CONF_FILE="/usr/local/etc/GeoIP.conf"

mkdir -p "${GEOIP_DIR}"
cd "${GEOIP_DIR}"

LICENSE_KEY=$(awk -F ' ' '/^#/ {next} $1=="LicenseKey" {print $2}' "${CONF_FILE}")
IPINFO_TOKEN=$(awk -F ' ' '/^#/ {next} $1=="IPINFO_TOKEN" {print $2}' "${CONF_FILE}")

if [ -z "${LICENSE_KEY}" ] || [ -z "${IPINFO_TOKEN}" ]; then
    echo "ERROR: Missing LicenseKey or IPINFO_TOKEN in ${CONF_FILE}" >&2
    exit 1
fi

# MaxMind City
fetch -q -o - "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=${LICENSE_KEY}&suffix=tar.gz" \
    | tar xz --strip-components=1 --wildcards "*.mmdb" 2>/dev/null || true
mv GeoLite2-City_*/GeoLite2-City.mmdb . 2>/dev/null || true

# ipinfo.io ASN (saved as Geolite2-ASN.mmdb instead of maxmind)
fetch -q -o GeoLite2-ASN.mmdb "https://ipinfo.io/data/free/asn.mmdb?token=${IPINFO_TOKEN}"

# Permissions
chown root:wheel *.mmdb 2>/dev/null || true
chmod 444 *.mmdb

# Restart ntopng (silent)
/usr/local/etc/rc.d/ntopng restart >/dev/null 2>&1 || true
UPDATER

# 3. Make executable
chmod 755 /usr/local/bin/ntopng-updategeo.sh

# 4. Run once (silent on success)
echo "→ Running initial update (this may take a few seconds)..."
/usr/local/bin/ntopng-updategeo.sh

echo "   Updater installed at: /usr/local/bin/ntopng-updategeo.sh"
echo "   Config file:          /usr/local/etc/GeoIP.conf"
echo ""
echo "Now add it to Cron (System → Settings → Cron):"
echo "   Command: /usr/local/bin/ntopng-updategeo.sh"
echo "   Run Weekly or Monthly at any hour you like (e.g. 3:00 AM)"
