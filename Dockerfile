FROM alpine:3.19 AS builder

# 安装依赖
RUN apk add --no-cache \
    openssl-dev \
    zlib-dev \
    git make \
    gcc \
    musl-dev \
    libbsd-dev \
    perl \
    luajit-dev

# 克隆 wrk2 仓库
RUN git clone --depth=1 https://github.com/giltene/wrk2.git
WORKDIR /wrk2

# 使用系统自带的 LuaJIT（不再自行编译）
# Alpine 的 luajit-dev 已包含 ARM64 可用的 libluajit
ENV LUAJIT_LIB=/usr/lib \
    LUAJIT_INC=/usr/include/luajit-2.1

# 替换老旧结构体
RUN sed -i 's/struct luaL_reg/luaL_Reg/g' src/script.c

# 编译 wrk2
RUN make

# 运行阶段
FROM alpine:3.19

# 安装运行时所需的 luajit 依赖库（包含 libluajit-5.1.so.2）
RUN apk add --no-cache luajit libgcc libstdc++

# 拷贝编译好的 wrk 二进制
COPY --from=builder /wrk2/wrk /usr/local/bin/wrk

ENTRYPOINT ["/usr/local/bin/wrk"]
