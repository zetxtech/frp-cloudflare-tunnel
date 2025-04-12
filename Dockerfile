# 使用官方cloudflared镜像作为基础
FROM cloudflare/cloudflared:2025.4.0 AS cloudflared

# 使用debian作为最终镜像
FROM debian:bullseye-slim

# 安装必要的工具
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    supervisor \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# 创建必要的目录
RUN mkdir -p /frp /scripts /var/log/supervisor

# 从cloudflared镜像复制cloudflared程序
COPY --from=cloudflared /usr/local/bin/cloudflared /usr/local/bin/

# 添加ARG以支持不同架构
ARG ARCH=amd64

# 下载并安装frps
RUN wget https://github.com/fatedier/frp/releases/download/v0.61.2/frp_0.61.2_linux_${ARCH}.tar.gz \
    && tar -xzf frp_0.61.2_linux_${ARCH}.tar.gz \
    && mv frp_0.61.2_linux_${ARCH}/frps /frp/ \
    && rm -rf frp_0.61.2_linux_${ARCH}* \
    && chmod +x /frp/frps

# 复制frps配置文件
COPY frps.toml /frp/

# 复制scripts脚本
COPY scripts/health_server.py /scripts/health_server.py
COPY scripts/health_check.sh /scripts/health_check.sh
RUN chmod +x /scripts/health_server.py
RUN chmod +x /scripts/health_check.sh

# 配置supervisor
COPY supervisord.conf /etc/supervisor/conf.d/

EXPOSE 8889

# 启动supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]