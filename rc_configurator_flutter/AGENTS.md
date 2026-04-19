## 编码约束
- 保持改动小而聚焦。
- 保持既有架构与命名风格。
- 非明确要求，不新增依赖。
- 不要顺手修改无关文件。
- 优先纯函数与可预测状态更新。

## 文件名称规范
- 文件名统一使用小写英文 + 下划线（snake_case）。
- 文件名与主要职责一致，不使用缩写和无意义前缀。


## 代码行数不能超过 100 行
- 每个文件的代码行数不能超过 140 行。
- 每个函数的代码行数不能超过 30 行。


## 文件组织结构
- UI组件在 `lib/src/compoents`。
- provider 位于 `lib/src/provider`。
- 页面位于 `lib/src/page`。
- svg组件在 `lib/src/compoents/svg/*.svg`。
- 通过 svg 生成 UI 组件在名称也必须和 svg 文件名一致 `lib/src/compoents/svg/ui`。
- svg 共用组件在 `lib/src/compoents/svg/common`。

## 测试
- provider 功能需要生成对应的测试文件。
- 需要测试每个 provider 的主要功能。