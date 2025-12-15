FROM alpine:latest AS builder

# 更新包索引并安装依赖
RUN apk update && apk add --no-cache \
    openssl-dev \
    zlib-dev \
    git \
    make \
    gcc \
    musl-dev \
    libbsd-dev \
    perl
    
# 克隆 wrk2 仓库
RUN git clone --depth=1 https://github.com/giltene/wrk2.git
WORKDIR /wrk2

# 替换为官方支持 ARM64 的 LuaJIT
RUN rm -rf deps/luajit && \
    git clone --branch v2.1 --depth=1 https://github.com/LuaJIT/LuaJIT.git deps/luajit

WORKDIR /wrk2/deps/luajit
RUN make && make install PREFIX=/usr/local

# 构建 wrk2
WORKDIR /wrk2
ENV LUAJIT_LIB=/usr/local/lib LUAJIT_INC=/usr/local/include/luajit-2.1

# 替换老旧结构体
RUN sed -i 's/struct luaL_reg/luaL_Reg/g' src/script.c

# 编译 wrk2 - 使用正确的链接器标志
RUN make WITH_LIBS="-latomic"

# 运行阶段，基于 Alpine，安装运行时依赖
FROM alpine:latest

# 安装运行时所需的库
RUN apk update && apk add --no-cache libgcc libstdc++

# 拷贝编译好的 wrk 二进制和 LuaJIT 库
COPY --from=builder /wrk2/wrk /usr/local/bin/wrk
COPY --from=builder /usr/local/lib/libluajit-5.1.so.2* /usr/lib/

ENTRYPOINT ["/usr/local/bin/wrk"]
