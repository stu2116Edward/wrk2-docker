# 最小化wrk Docker镜像构建
# 基于多阶段构建和Alpine Linux，最终镜像约8MB

# 阶段1: 编译层
FROM alpine:3.19 AS builder

# 安装构建依赖
RUN set -eux && apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    libbsd-dev \
    zlib-dev \
    openssl-dev \
    perl

# 克隆wrk2仓库 - 单独步骤便于缓存
RUN git clone https://github.com/giltene/wrk2 --depth 1

# 编译wrk2 - 调整make顺序
WORKDIR /wrk2
RUN set -eux && \
    # 先尝试make clean，如果失败则继续（首次构建可能没有可清理的）
    { make clean || true; } && \
    # 确保编译环境正确
    make WITH_OPENSSL=1 && \
    # 验证编译结果
    test -f wrk && \
    ls -lh wrk

# 精简二进制文件 - 单独步骤
RUN strip -v --strip-all wrk && \
    ls -lh wrk

# 阶段2: 运行层
FROM alpine:3.19

# 安装运行时依赖 - libgcc提供libgcc_s.so.1共享库
RUN apk add --no-cache libgcc

# 从编译层复制wrk二进制文件
COPY --from=builder /wrk2/wrk /usr/bin/wrk2

# 验证二进制文件可执行
RUN chmod +x /usr/bin/wrk2

# 设置入口点
ENTRYPOINT ["/usr/bin/wrk2"]
