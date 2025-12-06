# 最小化wrk Docker镜像构建
# 基于多阶段构建和Alpine Linux，最终镜像约8MB

# 阶段1: 编译层
FROM alpine:3.19 AS builder

# 安装构建依赖 - 添加必要的头文件和构建工具
RUN set -eux && apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    libbsd-dev \
    zlib-dev \
    openssl-dev \
    perl \
    # 添加编译wrk2所需的额外依赖
    linux-headers \
    build-base

# 克隆wrk2仓库 - 单独步骤便于缓存
RUN git clone https://github.com/giltene/wrk2 --depth 1

# 编译wrk2 - 修复编译问题
WORKDIR /wrk2
RUN set -eux && \
    echo "检查编译环境..." && \
    # 检查必要的文件是否存在
    ls -la && \
    # 查看Makefile内容
    head -50 Makefile && \
    # 显示环境信息
    gcc --version && \
    make --version && \
    # 尝试编译，添加详细输出
    echo "开始编译wrk2..." && \
    make -j$(nproc) WITH_OPENSSL=1 2>&1 | tee /tmp/build.log || (echo "编译失败，查看日志:" && cat /tmp/build.log && exit 1) && \
    # 验证编译结果
    test -f wrk && echo "编译成功!" && \
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
