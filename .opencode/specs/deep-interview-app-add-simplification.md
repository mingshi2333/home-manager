# Deep Interview Spec: Simplify New App Configuration

## Metadata

- Interview ID: 91c84f20-8b54-4df0-bf6a-613ac8c197ad
- Rounds: 4
- Final Ambiguity Score: 14.95%
- Type: brownfield
- Generated: 2026-03-08
- Threshold: 20%
- Status: PASSED

## Clarity Breakdown

| Dimension          | Score | Weight | Weighted |
| ------------------ | ----- | ------ | -------- |
| Goal Clarity       | 0.92  | 0.35   | 0.3220   |
| Constraint Clarity | 0.84  | 0.25   | 0.2100   |
| Success Criteria   | 0.88  | 0.25   | 0.2200   |
| Context Clarity    | 0.82  | 0.15   | 0.1230   |
| **Total Clarity**  |       |        | **0.8750** |
| **Ambiguity**      |       |        | **0.1495** |

## Goal

Simplify the workflow for adding a new standard application so that a user can usually declare it in one place and rely on automatic derivation for most repeated metadata, while keeping the current brownfield architecture recognizable and leaving room for special-case apps through an explicit extension path.

## Constraints

- The work may use medium-scale refactoring.
- The current modular Home Manager structure should remain recognizable.
- Standard nixGL-style apps are the primary target.
- Special-case apps do not need full unification in this round, but the design should leave a clear extension point for them.
- The result should improve the add-a-new-app path without requiring a full redesign of all app plumbing.

## Non-Goals

- Do not fully rewrite `nixgl-noimpure.nix` or unrelated runtime internals.
- Do not require every existing special-case app to migrate immediately.
- Do not optimize only documentation while leaving the actual config flow unchanged.
- Do not pursue a greenfield app framework disconnected from the current repo layout.

## Acceptance Criteria

- [ ] Adding a standard new app usually requires editing one source of truth.
- [ ] Common repeated fields can be omitted and derived automatically.
- [ ] The proposal clearly separates the standard path from the special-case extension path.
- [ ] The design explains how existing outputs still flow into packages, aliases, desktop entries, and MIME associations.
- [ ] The result includes a migration/compatibility story for existing app definitions.
- [ ] The documentation for adding an app becomes materially shorter and clearer.

## Assumptions Exposed & Resolved

| Assumption | Challenge | Resolution |
| ---------- | --------- | ---------- |
| The user might only want less boilerplate | Asked which core action should be simplified | The user wants entry point, boilerplate, and special-path consistency addressed together |
| The user might want only small local tweaks | Asked what refactor scope is acceptable | Medium refactoring is acceptable |
| Success might be subjective | Asked what would count as success | Success means one-place declaration and omission of most repeated fields |
| Special-case paths must be unified immediately | Contrarian question tested whether standard-path-only simplification would already be enough | This round may focus on the standard path, but should preserve a layered extension path for special apps |

## Technical Context

The current pipeline spreads app onboarding across multiple files: declaration in `nixgl-apps.nix`, enablement in `modules/nixgl-runtime.nix`, packaging in `modules/packages.nix`, alias/bin exposure in `modules/home-manager-commands.nix`, and desktop/MIME wiring in `modules/desktop-entries.nix`. The main friction is that app names and metadata are duplicated across declaration and enablement layers. Some apps also bypass the shared helper model, such as `modules/lenovo-legion.nix`, so a clean standard-path abstraction needs an explicit place for exceptions.

## Ontology (Key Entities)

| Entity | Fields | Relationships |
| ------ | ------ | ------------- |
| App definition | pkg, name, platform, optional metadata, optional overrides | Source of truth for a standard app |
| Enabled app set | app ids or enabled flags | Determines which definitions are materialized |
| Derived outputs | packages, aliases, bin scripts, desktop entries, MIME associations | Produced from app definitions |
| Special app extension path | custom script, desktop entry, wrapper, overrides | Handles apps that do not fit the standard model |
| App onboarding docs | steps, examples, defaults | Explains how users add new apps |

## Interview Transcript

<details>
<summary>Full Q&A (4 rounds)</summary>

### Round 1

**Q:** 如果这次要把“添加一个新应用”这件事做简化，你最希望被简化的核心动作是哪一个？
**A:** 同时兼顾以上三点。
**Ambiguity:** 54.75% (Goal: 0.72, Constraints: 0.20, Criteria: 0.22, Context: 0.60)

### Round 2

**Q:** 我现在看到两种方向：一种是“小改”，在现有 `mkNixGLApp` 上补默认值、减少重复字段；另一种是“中改”，把“定义 + 启用”合并成单一来源，甚至顺手统一像 `lenovo-legion` 这种旁路。你希望建议边界落在哪一层？
**A:** 允许中等重构。
**Ambiguity:** 32.25% (Goal: 0.82, Constraints: 0.75, Criteria: 0.30, Context: 0.66)

### Round 3

**Q:** 如果我最后给出一个“添加新应用的简化方案”，什么结果会让你觉得它真的成功了？
**A:** 新增应用只改一处；大部分字段可省略。
**Ambiguity:** 21.90% (Goal: 0.88, Constraints: 0.78, Criteria: 0.82, Context: 0.68)

### Round 4

**Q:** 如果这次方案完全不去统一 `lenovo-legion` 这类特殊路径，只把标准的新应用接入流程简化到“单点声明 + 自动推导”，你会觉得这个方案已经足够好吗？
**A:** 可以先分层处理。
**Ambiguity:** 14.95% (Goal: 0.92, Constraints: 0.84, Criteria: 0.88, Context: 0.82)

</details>
