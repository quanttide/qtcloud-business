# Contributing

## 适用范围

这里约束 `src/cli` 的命令实现、文档、检查与发布准备。

## 本地检查

改动 CLI 后，至少跑一遍：

```bash
cargo fmt --check
cargo test --locked
cargo clippy --locked -- -A warnings
```

## 文档同步

当新增、调整或重分类 CLI 命令时，要同步更新：

- `README.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `TODO.md`
- `docs/dev/index.md`

## 发布准备

CLI 版本发布前，先确认：

1. 工作区是干净的。
2. 版本号和 changelog 对齐。
3. `qtcloud-devops release audit -v cli/vX.Y.Z --scope cli` 通过。
4. 发布只走 `qtcloud-devops release publish`，不要直接 `cargo publish`。
5. 代码先合入 `main`，再做正式发布。

## 约定

- 新增命令时，优先复用现有结构。
- 只做本地计算的功能，不要提前引入存储或服务端依赖。
- 先把行为写清楚，再扩展实现。
