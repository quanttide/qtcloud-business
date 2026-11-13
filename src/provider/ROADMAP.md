# ROADMAP — qtcloud-business-provider

数据面，应用侧集成层：下游 Lite / Site，上游 Studio 的报价与合同数据。**v0.1 里的角色 = 骨架探针**——模型未定不浇筑，只保证健康检查与部署通道可用。

## v0.1：骨架

- [x] 服务骨架：`/healthz` + 环境变量配置 + Dockerfile
- [ ] 部署管道：`provider/*` tag → 构建镜像（方案随 ACR / FC 选型定）

## 契约后（Studio 数据模型定型后接）

- [ ] 报价读取：列表（按客户搜索）+ 详情 + 版本历史，供 Lite / Site 消费
- [ ] 合同读取：列表（状态筛选）+ 签署进度，供 Lite 消费
- [ ] 只读优先：写入口仍只在 Studio，Lite / Site 不开写通道

## 远期

三端上游调用收敛至本服务；缓存视流量引入；先有真实痛点再立项。
