# Fedora KDE Wayland 应用兼容性修复

## What This Is

这是一个基于现有 Home Manager / nixGL 配置仓库的 brownfield 修复项目，目标是在当前 `Fedora + KDE + Wayland` 环境下修复桌面应用的启动失败、运行不稳定和剪贴板异常问题。重点不是重做整套框架，而是在现有声明式配置、启动包装和必要的系统级兼容设置上，把常用应用修到稳定可用。

## Core Value

当前这台 `Fedora + KDE + Wayland` 机器上的关键桌面应用必须能稳定启动并持续可用，不再依赖频繁重启来恢复。

## Requirements

### Validated

- ✓ 仓库已能通过 `flake.nix`、`home.nix`、`hosts/mingshi/home.nix` 和 `profiles/*.nix` 组合出可切换的 Home Manager 配置。 — existing
- ✓ 仓库已建立基于 `nixGL` 的桌面应用包装体系，并通过 `nixgl-apps.nix` 为多种 GUI 应用生成启动器、desktop entry 和别名。 — existing
- ✓ 仓库已为 `qq`、`zotero` 等桌面应用提供专门包装，并允许通过环境变量、平台模式和运行时脚本进行兼容性调整。 — existing
- ✓ 已建立 Fedora KDE Wayland 兼容策略边界，并通过 `local.nixgl` 导出可查询的 app policy 与 inventory。 — Validated in Phase 1: Compatibility Boundary
- ✓ 已建立 portal、IME、clipboard 的可重复会话验证路径，并为 `QQ` / `Zotero` 准备 shell 与 desktop 两条启动路径的基线验证资产。 — Validated in Phase 2: Session Validation

### Active

- [ ] 修复 `QQ` 在当前 `Fedora + KDE + Wayland` 环境下运行一段时间后复制粘贴失效、聊天框粘贴旧剪贴板内容的问题。
- [ ] 修复 `Zotero` 在当前环境下偶发无法启动或崩溃的问题，并让其达到可重复稳定启动。
- [ ] 排查并修复当前仓库中其它常用桌面应用在 `Fedora + KDE + Wayland` 下的启动失败或运行异常。
- [ ] 优先通过 Home Manager、`nixgl-apps.nix` 包装、环境变量、启动参数和必要的系统级兼容设置完成修复。

### Out of Scope

- 面向其它发行版、桌面环境或 host 的通用兼容性抽象重构。 — 本次范围明确只修当前 `Fedora + KDE + Wayland` 环境
- 大规模替换现有 Home Manager / nixGL 框架。 — 当前目标是修复稳定性问题，不是重写基础架构
- 以新增功能为主的应用扩展或包清单扩充。 — 本次聚焦已有应用的兼容与稳定性

## Context

当前代码库是一个基于 `flake.nix` 的个人 Home Manager 配置仓库，入口位于 `flake.nix`，通过 `hosts/mingshi/home.nix` 和 `home.nix` 组装模块，再由 `profiles/*.nix` 引入具体能力。图形应用的关键兼容层集中在 `modules/nixgl-runtime.nix` 与 `nixgl-apps.nix`，仓库已经为多个 GUI 应用生成 `nixGL` 包装、desktop entry 和命令别名。

已发现的具体信号包括：系统日志中 `qq` 持续出现 `Maximum number of clients reached`，与用户描述的剪贴板异常相互印证；`coredumpctl` 中已有 `zotero-8.0.3` 的 `SIGSEGV` 崩溃记录；`qq` 与 `zotero` 的现有包装分别定义在 `nixgl-apps.nix` 中，当前分别采用 `wayland` 与 `x11` 平台模式启动。

到目前为止，项目已经完成前两阶段的基础工作：Phase 1 把 Fedora KDE Wayland 兼容策略边界固定为声明式 app policy + inventory 导出；Phase 2 增加了用于 `QQ` 和 `Zotero` 的会话验证脚本、checklist、runbook 和证据目录结构，使后续修复能在同一套基线上前后对比。

当前修复目标是围绕这些已有包装和 Fedora 图形会话兼容层做增量修正，必要时允许纳入系统级设置，例如 portal、clipboard、Wayland/XWayland 或相关运行时依赖的兼容调整。

## Constraints

- **Environment**: 仅针对当前 `Fedora + KDE + Wayland` 机器修复 — 用户明确本次不要求跨 host 或跨发行版通用
- **Architecture**: 优先保留现有 Home Manager / nixGL 结构 — 仓库已经有明确的模块化入口和包装体系
- **Remediation Style**: 优先配置修复，其次允许必要的系统级兼容调整 — 用户希望优先改配置而不是重做架构
- **Success Bar**: 至少达到“能稳定启动” — 这是用户明确给出的完成标准

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| 以现有 Home Manager / nixGL 仓库为基础做 brownfield 修复 | 当前问题发生在已有框架与已安装应用上，先修复现状比重建更直接 | — Pending |
| 首批聚焦 `QQ`、`Zotero` 和其它 Fedora Wayland 下异常应用 | 这是用户明确指出且已有日志/coredump 佐证的问题集合 | — Pending |
| 修复范围限定为当前 `Fedora + KDE + Wayland` 环境 | 用户明确表示只修当前环境，不要求跨环境通用性 | — Pending |
| 优先采用配置层和包装层修复，必要时允许系统级兼容调整 | 这样最贴合当前仓库职责，也符合用户的修复偏好 | — Pending |
| 兼容策略边界保持为 app-level policy in `nixgl-apps.nix` + session-level wiring in `modules/` | 避免把 Fedora/KDE/Wayland 特有会话逻辑继续散落进通用 wrapper 生成路径 | Validated in Phase 1 |
| 在 app-specific 修复前先建立 `QQ` / `Zotero` 的 shell 与 desktop 双路径会话验证基线 | 先区分会话级问题和应用级问题，后续修复才能有可比对证据 | Validated in Phase 2 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-02 after Phase 2 completion*
