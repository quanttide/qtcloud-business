# Studio ROADMAP

## 新增 packages

- [ ] `qtcloud-quote`：报价组件包（报价单模型、版本管理、历史记录）
- [ ] `qtcloud-contract`：合同组件包（合同模板、签约流程、履约跟踪）

## 主程序改造

- [ ] 页面路由：增加报价页、合同页，支持页面间导航
- [ ] 集成 `qtcloud-quote`：报价页展示报价单列表、明细与版本
- [ ] 集成 `qtcloud-contract`：合同页展示签约进度与履约状态
- [ ] 根据路由拆分 `main.dart`，避免单一文件膨胀
