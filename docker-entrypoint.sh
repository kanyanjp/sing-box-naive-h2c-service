#!/bin/sh
set -eu

PORT="${PORT:-8843}"
SING_BOX_USERNAME="${SING_BOX_USERNAME:-ccds}"
SING_BOX_PASSWORD="${SING_BOX_PASSWORD:-Hoc5l?wL.rbP.yg!}"
SING_BOX_LOG_LEVEL="${SING_BOX_LOG_LEVEL:-info}"

case "$PORT" in
  ''|*[!0-9]*)
    echo "PORT must be an integer, got: $PORT" >&2
    exit 1
    ;;
esac

json_escape() {
  printf '%s' "$1" | sed \
    -e 's/\\/\\\\/g' \
    -e 's/"/\\"/g'
}

mkdir -p /etc/sing-box

cat > /etc/sing-box/config.json <<EOF
{
  "log": {
    "level": "$(json_escape "$SING_BOX_LOG_LEVEL")"
  },
  "inbounds": [
    {
      "type": "naive",
      "tag": "naive-in",
      "listen": "0.0.0.0",
      "listen_port": $PORT,
      "network": "tcp",
      "users": [
        {
          "username": "$(json_escape "$SING_BOX_USERNAME")",
          "password": "$(json_escape "$SING_BOX_PASSWORD")"
        }
      ]
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct",
      "bind_interface": "eth0"
    }
  ],
  "route": {
    "auto_detect_interface": false,
    "rules": [
      {
        "rule_set": "geoip-cn",
        "action": "reject"
      },
      {
        "rule_set": "geosite-geolocation-!cn",
        "action": "route",
        "outbound": "direct"
      },
      {
        "rule_set": "geosite-cn",
        "action": "reject"
      }
    ],
    "rule_set": [
      {
        "tag": "geoip-cn",
        "type": "local",
        "format": "binary",
        "path": "/etc/sing-box/rules/geoip-cn.srs"
      },
      {
        "tag": "geosite-geolocation-!cn",
        "type": "local",
        "format": "binary",
        "path": "/etc/sing-box/rules/geosite-geolocation-!cn.srs"
      },
      {
        "tag": "geosite-cn",
        "type": "local",
        "format": "binary",
        "path": "/etc/sing-box/rules/geosite-cn.srs"
      }
    ],
    "final": "direct"
  }
}
EOF

sing-box check -c /etc/sing-box/config.json
exec sing-box run -c /etc/sing-box/config.json
