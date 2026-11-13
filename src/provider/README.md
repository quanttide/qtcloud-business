# qtcloud-business provider

量潮商务云的服务端骨架：为 Lite / Site 预留统一数据通道。当前仅健康检查，报价与合同数据以 Studio 仓内 seed JSON 起步，服务端接口按需立项后在此挂载。

## 运行

```bash
LISTEN_ADDR=:8080 go run ./cmd/server
```

## 接口

| 方法 | 路径 | 说明 |
|:-----|:-----|:-----|
| GET | `/healthz` | 健康检查 |

技术栈对齐 qtclass-provider 惯例：Go 标准库 + `net/http`，无第三方依赖；配置经环境变量注入（`LISTEN_ADDR`）。

## 验证

```bash
go build ./... && go vet ./...
```

路线图见 `ROADMAP.md`。
