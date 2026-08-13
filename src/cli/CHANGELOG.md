# Changelog

## [Unreleased]

### Fixed
- `quote` 工时模式拒绝 `hours <= 0`，不再输出 `NaN` 单价。
- `quote --hours` 增加 `allow_hyphen_values`，负数时长（如 `-5`）不再被 clap 误判为非法参数，改为业务校验报错。

### Changed
- 后续未发布的改动继续记录在这里。

## [0.1.0] - 2026-08-13

### Added
- `quote` 命令新增明细报价模式，支持 `--project`、`--client`、可重复的 `--item` 和 `--note`。
- `quote --example retrospective` 提供了一个可直接复盘的内置报价样例。
- 旧的工时报价模式继续保留，可继续用 `--hours`、`--level`、`--premium` 快速计算。

### Changed
- 报价输入现在会先做本地校验，再输出结果。
- 工时报价参数与明细报价参数不能混用，避免静默忽略输入。

### Fixed
- 明细报价会拒绝 `NaN`、`inf` 以及非法折扣值。
- 自定义明细报价必须显式填写项目名和客户名，避免样例误标。
