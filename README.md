# 量潮商务云

## 仓库结构

```
src/studio/                – Flutter 客户端
  lib/                   – 主程序
    models/              – 数据模型（报价、合同、履约）
    screens/             – 页面层
    widgets/             – 共享组件（状态徽章等）
  assets/data/           – JSON seed 数据
  test/                  – 组件测试
docs/                      – 工作文档
  dev-guide/                – 产品需求文档（报价制定、合同管理、产品边界）
examples/                  – 示例与原型
```

## CLI 报价计算

`src/cli` 提供 `qtcloud-business quote` 命令。当前版本只做无状态计算，不保存报价单，也不读取服务端数据。

原有工时报价模式继续可用：

```bash
qtcloud-business quote --hours 8 --level advanced --premium 0
```

新增明细报价模式用于计算报价单明细，金额单位为万元。`--item` 格式为 `名称|单价|数量|折扣`，可重复传入：

```bash
qtcloud-business quote \
  --project "议事决议数据需求点" \
  --client "量潮科技（内部项目）" \
  --item "议事决议数据-决议档案|0.4|1|1" \
  --item "议事决议数据-治理视图|0.2|1|1" \
  --item "周会决议汇总与历史批量整理|0.2|1|1" \
  --note "成本法约0.5万元；市场法约1.2万元；内部价=市场价×7折≈0.8万元"
```

也可以直接运行内置复盘样例：

```bash
qtcloud-business quote --example retrospective
```
