# 量潮商务云数据服务（v0.1）

零依赖 Node.js 单文件 API，为 Studio 提供多人共享数据：业务 / 报价 / 合同的增删改查。
数据整体存为一个 JSON 文件（`data/state.json`，原子写盘），首次启动自动以 Studio 的 seed 初始化。

## 接口

所有接口 JSON；除 `GET /api/health` 外，设置过 `QTBUS_TOKEN` 时需带请求头 `X-Auth-Token: <token>`。

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/health` | 健康检查 |
| GET | `/api/state` | 全量数据（businesses/quotations/contracts/templates） |
| POST | `/api/businesses` | 新建业务（body 为实体 JSON，须含 id） |
| PUT | `/api/businesses/{id}` | 更新业务（body id 须与 URL 一致） |
| DELETE | `/api/businesses/{id}` | 删除业务，级联删除名下报价与合同 |
| POST/PUT/DELETE | `/api/quotations…`、`/api/contracts…` | 同上（不级联） |

## 本地运行

```bash
node server.js            # 默认 :8787，无鉴权
PORT=9000 QTBUS_TOKEN=test node server.js
```

## 部署到 ECS

1. 上传 `server.js`、`qtbus-server.service` 到服务器，如 `/opt/qtcloud-business/server/`
2. 生成并设置令牌：

   ```bash
   openssl rand -hex 24
   # 写入 qtbus-server.service 的 QTBUS_TOKEN
   ```

3. 安装并启动：

   ```bash
   sudo cp qtbus-server.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now qtbus-server
   curl http://127.0.0.1:8787/api/health
   ```

4. nginx 反代 + HTTPS：参考 `nginx-qtbus-api.conf.example`，
   DNS 给 `api.business.cloud.quanttide.com` 加 A 记录指向 ECS
5. 数据备份：定时拷贝 `data/state.json` 即可（如 crontab 每小时一次）

## 与前端的对接

Studio 构建时注入两个 dart-define（见 `.github/workflows/deploy-studio.yml`）：

- `API_BASE`：如 `https://api.business.cloud.quanttide.com/api`
- `QTBUS_TOKEN`：与服务端一致

本地开发默认连 `http://localhost:8787/api`。

## 已知边界（v0.1）

- 无用户体系：共享令牌鉴权，适合内部两三人使用
- 无实时推送：他人修改需点侧边栏「刷新」拉取
- 离线时改动只存本机缓存，恢复后需手动刷新同步（有未同步改动时会阻止覆盖）
