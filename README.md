# sing-box-naive-h2c-service

这个仓库用于部署一个纯服务端的 `sing-box` 容器，假设 TLS 由外部平台终止：

- 平台入口负责 HTTPS/TLS
- 平台入口把 `HTTP/2 CONNECT` 原样转发到本容器
- 容器内的 `sing-box` 只监听明文 `h2c`
- 容器默认监听 `PORT`，如果平台没有注入，则回退到 `8843`

这意味着容器本身不处理证书，也不做 TLS 握手。它只负责 `naive` 协议鉴权和转发。

## 默认配置

- 用户名: `ccds`
- 密码: `Hoc5l?wL.rbP.yg!`
- 监听端口: `$PORT` 或 `8843`
- 基础镜像: `ghcr.io/sagernet/sing-box:latest`
- 规则集: 构建时打包进镜像

运行时可以通过环境变量覆盖：

- `PORT`
- `SING_BOX_USERNAME`
- `SING_BOX_PASSWORD`
- `SING_BOX_LOG_LEVEL`

## 仓库结构

- `Dockerfile`: 生产镜像定义
- `docker-entrypoint.sh`: 启动时生成 `sing-box` 配置并启动服务
- `.github/workflows/build-amd64.yml`: GitHub Actions 多架构镜像构建流程

## 本地构建

```bash
cd /home/cnic/work/tmp/naive-caddy-h2c-demo
docker build -t naive-sing-box-service .
```

## 本地运行

容器内只有明文 `h2c`，所以本地直接跑起来之后，前面仍然需要一个支持 `HTTP/2 CONNECT` 透传的入口层才能作为完整的 `naive` 服务使用。

```bash
cd /home/cnic/work/tmp/naive-caddy-h2c-demo
docker run --rm -p 8843:8843 naive-sing-box-service
```

覆盖默认账号密码与端口：

```bash
docker run --rm \
  -e PORT=9000 \
  -e SING_BOX_USERNAME=ccds \
  -e 'SING_BOX_PASSWORD=Hoc5l?wL.rbP.yg!' \
  -p 9000:9000 \
  naive-sing-box-service
```

## 线上平台部署要求

- 平台入口必须终止 TLS
- 平台入口必须支持 HTTP/2
- 平台入口必须允许并转发 `HTTP/2 CONNECT`
- 平台入口转发到容器时，应把流量送到容器的 `$PORT` 或 `8843`
如果平台会拦截、降级或拒绝 `CONNECT`，那么 `naive` 无法工作。

## 镜像行为

容器启动时会：

1. 读取 `PORT`、`SING_BOX_USERNAME`、`SING_BOX_PASSWORD`、`SING_BOX_LOG_LEVEL`
2. 生成 `/etc/sing-box/config.json`
3. 先执行 `sing-box check`
4. 再执行 `sing-box run`

镜像构建时会预下载这些规则集到 `/etc/sing-box/rules/`：

- `geoip-cn.srs`
- `geosite-geolocation-!cn.srs`
- `geosite-cn.srs`

生成的服务端配置等价于：

- 一个 `naive` 入站
- 监听 `0.0.0.0:$PORT`
- 使用单用户鉴权
- 先匹配中国 IP，命中后直接拒绝
- 再匹配 `geosite-geolocation-!cn`，命中后明确走 `direct`
- 最后匹配 `geosite-cn`，命中后拒绝
- 默认出站为 `direct`

## GitHub Actions

[build-amd64.yml](/home/cnic/work/tmp/naive-caddy-h2c-demo/.github/workflows/build-amd64.yml) 会在下面场景构建 `linux/amd64` 和 `linux/arm64` 镜像：

- push 到 `main`
- 打 tag
- pull request
- 手动触发

对于非 `pull_request` 事件，工作流会登录 GHCR 并推送镜像，发布标签固定为 `latest`。
