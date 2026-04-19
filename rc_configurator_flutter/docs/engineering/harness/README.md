# Harness Engineering（Flutter 规范版）

本项目采用轻量 Harness，以 Flutter 项目常见目录习惯组织：

- 规则放根目录：`AGENTS.md`
- 工程文档放 `docs/engineering/`
- 自动化脚本放 `tool/`

## 目录结构

- `AGENTS.md`：智能体全局规则
- `docs/engineering/harness/README.md`：Harness 说明
- `docs/engineering/harness/task_template.md`：任务契约模板
- `tool/harness/preflight.sh`：统一预检脚本

## 执行方式

```bash
bash tool/harness/preflight.sh
```

## 设计原则

- 单一入口：一个预检脚本完成 Analyze + Test
- 低耦合：Harness 不侵入业务代码
- 可迁移：目录命名与 Flutter 社区习惯一致
- 可维护：文档与脚本路径稳定、语义清晰

## 完成定义

- 行为满足任务目标
- `flutter analyze` 通过
- `flutter test` 通过
- 输出变更摘要与风险说明
