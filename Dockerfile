FROM alpine:3.12 AS builder

# 构建依赖：使用 build-base（包含 gcc/g++/make/ libc-dev），并添加 linux-headers
RUN apk add --no-cache \
    build-base \
    linux-headers \
    openssl-dev \
    zlib-dev \
    git \
    libbsd-dev \
    perl

# 克隆 wrk2 仓库
RUN git clone --depth=1 https://github.com/giltene/wrk2.git /wrk2
WORKDIR /wrk2

# 使用官方 v2.1 的 LuaJIT（更好支持部分架构）
RUN rm -rf deps/luajit && \
    git clone --branch v2.1 --depth=1 https://github.com/LuaJIT/LuaJIT.git deps/luajit

WORKDIR /wrk2/deps/luajit
RUN make && make install PREFIX=/usr/local

# 回到 wrk2 并设置 LuaJIT 路径以便编译
WORKDIR /wrk2
ENV LUAJIT_LIB=/usr/local/lib LUAJIT_INC=/usr/local/include/luajit-2.1

# 替换老旧结构体名（保留容错）
RUN sed -i 's/struct luaL_reg/luaL_Reg/g' src/script.c || true

# 编译 wrk2
RUN make

# 运行阶段，基于 Alpine，安装运行时依赖
FROM alpine:3.12

# 运行时所需的 luajit 和标准库
RUN apk add --no-cache luajit libgcc libstdc++

# 拷贝编译好的 wrk 二进制和 LuaJIT 库
COPY --from=builder /wrk2/wrk /usr/local/bin/wrk
COPY --from=builder /usr/local/lib/libluajit-5.1.so.2* /usr/lib/

ENTRYPOINT ["/usr/local/bin/wrk"]
