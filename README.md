# ntopng-geoip
Script to add Geo data to NtopNG - Opnsense

- You will need to get license key for https://ipinfo.io/ and https://www.maxmind.com/
- it should be free ( currently) there may be limits so do not download it too often - week/month
- when this is setup you can add it to Cron on Opnsene to run automatically

```bash
# Usage with fetch:
fetch -o - https://raw.githubusercontent.com/ghostersk/ntopng-geoip/refs/heads/main/install-ntopng-geoip.sh \
   | sh -s -- YOUR_MAXMIND_LICENSE_KEY_HERE your_ipinfo_token_here
# Usage with curl:
curl -fsSL https://raw.githubusercontent.com/ghostersk/ntopng-geoip/refs/heads/main/install-ntopng-geoip.sh \
   | sh -s -- YOUR_MAXMIND_LICENSE_KEY_HERE your_ipinfo_token_here
```
