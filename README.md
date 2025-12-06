# wrk2-docker

## 使用说明

### 获取压测脚本
```bash
curl -L -o ddos.lua https://raw.githubusercontent.com/stu2116Edward/wrk2-docker/refs/heads/main/ddos.lua
```

### 执行压测
```bash
docker run --rm \
--name wrk2 \
--user root \
--network host \
--cpuset-cpus="0" \
-v "$PWD/ddos.lua":/scripts/ddos.lua \
stu2116edwardhu/wrk2 \
-H "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36" \
-t1 -c100 -R10000 -d10m -s /scripts/ddos.lua https://example.com
```

**参数说明**：  
- `-t1`：发起 1 条线程。
- `-c100`：维持 100 个并发 TCP 连接。
- `-R10000`：目标吞吐量为 10000 RPS（Requests Per Second）,wrk2 会尝试把请求速率稳定在这一水平。
- `-d10m`：压测持续 10 分钟（10 minutes）。
- `-s /scripts/ddos.lua`：加载映射在容器内部的 Lua 脚本 /scripts/ddos.lua
- `https://example.com`：压测目标站点  
