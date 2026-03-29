FROM ghcr.io/sagernet/sing-box:latest

RUN mkdir -p /etc/sing-box/rules \
    && wget -O /etc/sing-box/rules/geoip-cn.srs https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs \
    && wget -O /etc/sing-box/rules/geosite-geolocation-!cn.srs https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-geolocation-!cn.srs \
    && wget -O /etc/sing-box/rules/geosite-cn.srs https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-cn.srs

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8843

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
