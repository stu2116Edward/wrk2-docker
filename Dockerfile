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
    perl \
    # 克隆并编译wrk
    && git clone https://github.com/giltene/wrk2 --depth 1 && \
    cd wrk2 && \
    make clean && \
    make WITH_OPENSSL=1 \
    && ls -lh /wrk2/wrk \
    && strip -v --strip-all /wrk2/wrk \
    && ls -lh /wrk2/wrk

# 阶段2: 运行层
FROM alpine:3.19

# 安装运行时依赖 - libgcc提供libgcc_s.so.1共享库
RUN apk add --no-cache libgcc

# 从编译层复制wrk二进制文件
COPY --from=builder /wrk2/wrk /usr/bin/wrk2

# 设置入口点
ENTRYPOINT ["/usr/bin/wrk2"]
