# 使用固定 Alpine 版本以提高可重复性
FROM alpine:3.18 AS builder

ENV LANG=C.UTF-8
WORKDIR /build

# 安装构建依赖
RUN set -eux; \
    apk update; \
    apk add --no-cache --virtual .build-deps \
        build-base \
        linux-headers \
        openssl-dev \
        zlib-dev \
        git \
        perl \
        libbsd-dev \
        curl \
        ca-certificates

# 克隆 wrk2 仓库
RUN git clone --depth=1 https://github.com/giltene/wrk2.git /wrk2
WORKDIR /wrk2

# 使用官方 LuaJIT v2.1（支持较新架构）
RUN set -eux; \
    rm -rf deps/luajit; \
    git clone --branch v2.1 --depth=1 https://github.com/LuaJIT/LuaJIT.git deps/luajit

WORKDIR /wrk2/deps/luajit
# 编译并安装 LuaJIT 到 /usr/local（在 builder 中）
RUN set -eux; \
    # LuaJIT 的默认 Makefile 在 Alpine (musl) 下通常可以直接 make
    make && make install PREFIX=/usr/local

# 回到 wrk2 源码目录，修补小差异并编译 wrk2
WORKDIR /wrk2
RUN set -eux; \
    # 某些系统源代码中仍使用过时的 luaL_reg 名称，做兼容替换
    if grep -q "luaL_reg" src/script.c 2>/dev/null; then \
      sed -i 's/struct luaL_reg/luaL_Reg/g' src/script.c || true; \
    fi; \
    # 对于某些架构需要 -latomic，先试常规 make，必要时重试带 -latomic
    if make; then echo "wrk built"; else make WITH_LIBS="-latomic"; fi

# 运行时阶段使用更精简的镜像
FROM alpine:3.18 AS runtime

# 运行时依赖（libgcc/libstdc++ 用于一些动态库）
RUN set -eux; \
    apk update; \
    apk add --no-cache libgcc libstdc++ ca-certificates

# 拷贝 wrk 可执行文件
COPY --from=builder /wrk2/wrk /usr/local/bin/wrk

# 拷贝 LuaJIT 运行时库（如果存在）
# 在某些构建中库名可能为 libluajit-5.1.so.2 或 libluajit-5.1.so
# 使用通配符并容错
COPY --from=builder /usr/local/lib/libluajit-5.1.so.2* /usr/lib/ 2>/dev/null || true
COPY --from=builder /usr/local/lib/libluajit-5.1.so* /usr/lib/ 2>/dev/null || true

# 确保可执行权限
RUN chmod +x /usr/local/bin/wrk || true

ENTRYPOINT ["/usr/local/bin/wrk"]
