# Changelog

## [studio/v0.1.0-alpha.1] - 2026-08-10

### 新增
- Flutter 工程初始化（android/ios/linux/macos/web/windows 全平台）
- 部署 CI：tag `studio/*` 触发 Web 构建 → OSS 上传 → CDN 刷新（.github/workflows/deploy-studio.yml）
- 商务工作台仪表盘：统计卡片（报价总数/已确认/待签署/已签署）、报价与合同列表、新建入口
- 报价制定（US1）：方案模板选择 → 客户信息 → 产品明细/价格/折扣编辑 → 导出 PDF 弹窗
- 报价历史（US2）：按客户搜索列表 + 详情页版本历史（当前/历史版本）
- 合同生成（US3）：合同模板选择 → 客户信息 → 条款预览
- 签署进度（US4）：发送→签署→归档步骤条、状态筛选（待签署/已签署/已归档）、签署提醒
- 模板库（报价/合同模板）与报价版本历史接入 seed 数据（assets/data/seed_business.json）
- 数据模型：Quotation/QuotationVersion/QuotationProduct、Contract/Fulfillment、BusinessTemplate、BusinessData 加载器

### 变更
- 页面路由：工作台 → 报价/合同列表 → 详情/新建，桌面端侧边栏 + 响应式布局（<640 移动端）
- widgets 按 common/cards/dialogs 分组（对齐 qtdata 结构）

### 测试
- 组件测试 4 个：仪表盘渲染、报价详情+导出、按客户搜索、合同签署进度+提醒
