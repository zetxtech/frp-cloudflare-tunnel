# frp-cloudflare-tunnel
借助cloudflare tunnel实现在容器平台的frp内网穿透

相比客户端服务器直接使用 tunnel 的优势是可用性大大增强，不用担心因为客户端连接不上 cloudflare 服务导致的断联，只需能够连通映射出来的TCP端口即可

## 使用说明
不修改 frps 配置文件：使用镜像`ghcr.io/madisonwirtanen/frp-cloudflare-tunnel:main`

自定义 frps 配置文件：fork 仓库后修改`frps.toml`文件

环境变量（必填）：`CLOUDFLARED_TOKEN`值为 Cloudflare Tunnel 的令牌`eyxxxxxx`

### Cloudflare Tunnel 面板配置
公共主机名处添加类型为`TCP`，URL 为`localhost:8080`，公共主机名如`frp.example.com`

### 客户端配置
参考[文档](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/)安装cloudflared
首先执行以下命令测试上一步的公共主机名如`frp.example.com`是否能成功映射到本地，不报错即是连接成功
```sh
cloudflared access tcp --hostname frp.example.com --url localhost:7000
```
再将以下命令中的`frp.example.com`**替换为实际的主机名**后执行
```sh
sudo bash -c 'cat > /etc/systemd/system/cloudflared-tcp.service <<EOF
[Unit]
Description=Cloudflared TCP Access Service
After=network.target

[Service]
ExecStart=/usr/local/bin/cloudflared access tcp --hostname frp.example.com --url localhost:7000
Restart=on-failure
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cloudflared

[Install]
WantedBy=multi-user.target
EOF
&& systemctl daemon-reload
&& systemctl enable cloudflared-tcp.service
&& systemctl start cloudflared-tcp.service'
```
参考[ frp 官方文档](https://gofrp.org/zh-cn/docs/)配置**frpc**

frpc 的示例配置文件`frpc.toml`如下，注意这里的`auth.token`需要和服务端的`frps.toml`中相同，域名和服务端口按实际更改
```toml
serverAddr = "127.0.0.1"
serverPort = 7000

auth.method = "token"
auth.token = "frp-cloudflare-tunnel"

#http(s)实例
[[proxies]]
name = "your_app_name"
type = "http"
localIP = "127.0.0.1"
localPort = 3000 # 服务端口
customDomains = ["subdomain.example.com"]
```
子域名的添加可以直接在 Cloudflare Tunnel 面板配置，公共主机名处添加类型为`HTTP`，URL 为`localhost:8080`，公共主机名如`subdomain.example.com`即可

注意多个 http(s) 实例添加子域名时 URL 也都为`localhost:8080`，只需主机名一一对应即可

## 保活配置
将容器的`8889`端口通过容器平台分配的URL暴露至公网，定期访问该URL即可实现保活
