# qtcloud-business-site

量潮商务云展示站：对外讲清商务云的定位（报价制定 + 合同管理）、服务对象与和销售云的边界。基于 React 19 + TypeScript + Vite 构建，遵循 `qtclass-site` 惯例。

## 开发

```bash
npm install
npm run dev      # 本地预览
npm run build    # tsc + vite 构建
npm run lint
npm test
npm run preview
```

## 结构

```
data/home/index.md    # 首页内容（业务定位、边界、核心指标），置于 src 之外
src/
├── App.tsx           # 路由装配（/ 与未知回首页）
├── routes.ts         # 路由路径与站外连接（studio / lite）
├── components/       # Layout（导航 + 页头）/ Markdown（GFM 渲染）
├── pages/Home.tsx    # 首页（剥 frontmatter 后渲染 markdown）
└── utils/            # frontmatter 解析与剥离
```

## 内容数据

`data/home/index.md` 为产品需求文档（`docs/dev-guide/index.md`）的对外摘要静态副本，页面经 `import.meta.glob`（根锚定路径 `/data/home/...`）装载并剥离 frontmatter。内容改动先改需求文档，再回流此处。

## 部署

链路：推送 `site/*` tag → GitHub Actions 构建 → OSS 桶 `qtcloud-business-site` → CDN `business.cloud.quanttide.com`（与 studio 同域不同桶时按实际 CDN 配置调整）。

- 流水线：`.github/workflows/deploy-site.yml`（只由 tag 触发）
- 版本与发布：见 [CHANGELOG.md](CHANGELOG.md)
