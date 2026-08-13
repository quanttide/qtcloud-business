# TODO

## `src/cli/src/business/quote.rs`

- [ ] 拆分 `QuoteArgs`、模式判断、计算逻辑和输出格式，减少单文件膨胀。
- [ ] 把 `retrospective` 样例数据移到独立常量/fixture 文件，方便后续补更多样例。
- [ ] 给 quote 命令补充更清晰的帮助说明和参数示例。

## `src/cli/docs/dev/index.md`

- [ ] 补完整 CLI 命令地图，说明 `status`、`quote` 和未来服务端接口的边界。
- [ ] 明确当前 quote 只做本地计算，不存储、不调用服务端。

## `src/cli/CONTRIBUTING.md`

- [ ] 补齐发布前检查清单和 release audit 操作顺序。
- [ ] 说明新增命令或参数时必须同步更新 CHANGELOG、ROADMAP 和 TODO。
