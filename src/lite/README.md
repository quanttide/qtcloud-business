# 量潮商务云 Lite

商务经理的轻量查看端：微信式外壳——顶部 AppBar「量潮商务云」，底部三页签（报价 / 合同 / 我的）。只看不建：报价与合同的增删改在 Studio 完成，Lite 负责随时查。

Web 形态（不发小程序），React + Vite + TypeScript，与 `src/site` 同构；遵循 `qtclass-lite` 惯例。部署走 `.github/workflows/deploy-lite.yml`（`lite/*` tag → OSS 桶 `qtcloud-business-lite` + CDN `lite.business.cloud.quanttide.com`）。

## 开发

```bash
npm install
npm run dev      # 本地预览
npm run build    # tsc + vite 构建
npm run lint
npm test
```

## 结构

```
src/
├── routes.ts          # 路由路径与页签定义（唯一来源）
├── pages/             # 三页：Quotations（报价）/ Contracts（合同）/ Mine（我的骨架）
├── components/        # AppBar / TabBar（微信式外壳）
└── App.tsx            # 外壳装配，路由表单独导出便于测试
```

## 数据面

契约静态先行：三页当前为静态骨架，数据源待 provider 立项后接入，页面不动。增删改不进 Lite——Studio 是唯一写入口。

## 部署

链路：推送 `lite/*` tag → GitHub Actions（本包构建）→ OSS 桶 `qtcloud-business-lite` → CDN `lite.business.cloud.quanttide.com`。首发待版本号确认后切 `lite/<版本>` tag 触发。
