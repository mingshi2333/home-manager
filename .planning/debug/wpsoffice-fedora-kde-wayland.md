---
status: investigating
trigger: "/gsd:debug 调试 wpsoffice 在 Fedora KDE Wayland 上启动即崩溃的问题。已知症状：systemd-coredump 显示 `wpsoffice /prometheus` 收到 SIGSEGV，栈顶在 `QGuiApplicationPrivate::createEventDispatcher`，涉及 WPS 自带 Qt5 xcb 平台插件 `libqxcb.so` / `libQt5XcbQpaKso.so.5`。请在当前仓库中自主调查：1) 找出 WPS 是否已被 nixGL 或其他 wrapper 包装；2) 找出仓库中与 Wayland/X11、Qt、fcitx、环境变量相关的配置；3) 基于代码和崩溃栈给出最可能根因排序；4) 如果能明确最小修复方案，指出应改哪些文件与为什么。不要改代码，只返回结构化调试结论、证据路径和建议验证步骤。"
created: 2026-04-12T00:00:00Z
updated: 2026-04-12T00:24:00Z
---

## Current Focus

hypothesis: 根因调查已同步到当前规划方向：仓库已有成熟 wrapper/catalog/desktop-mime 覆盖机制，WPS 的缺口是“未纳入该机制”，因此当前默认启动路径无法被 repo 强制切到 QT_QPA_PLATFORM=xcb
test: 本阶段不再执行新实验，只保留下一步为按该机制实现最小修复（新增 WPS wrapper + desktop entry/mime override，并避免默认入口继续直连 upstream）
expecting: 后续执行修复时可直接复用现有 nixgl-apps + desktop-entries 组装链，而无需改 upstream 包
next_action: wait for approval to implement wrapper-based WPS repair

## Symptoms

expected: wpsoffice 在 Fedora KDE Wayland 环境下稳定启动
actual: wpsoffice 启动即崩溃，systemd-coredump 显示 wpsoffice /prometheus 收到 SIGSEGV
errors: SIGSEGV; 栈顶在 QGuiApplicationPrivate::createEventDispatcher; 涉及 WPS 自带 Qt5 xcb 平台插件 libqxcb.so / libQt5XcbQpaKso.so.5
reproduction: 在 Fedora KDE Wayland 会话中启动 wpsoffice
started: 未说明

## Eliminated

## Evidence

- timestamp: 2026-04-12T00:18:00Z
  checked: modules/packages.nix
  found: home.packages 同时包含 config.local.nixgl.appPackages 与直接安装的 pkgs.wpsoffice-cn；当前 WPS 至少被直接安装进 profile
  implication: 如果没有单独的 WPS wrapper/desktop override，菜单或文件关联很可能仍直接命中 upstream WPS desktop/binary

- timestamp: 2026-04-12T00:18:30Z
  checked: modules/nixgl-runtime.nix + modules/desktop-entries.nix
  found: 仓库已把 nixgl-apps.nix 导出的 desktopEntries/mimeAssociations 注入 xdg.desktopEntries 与 xdg.mimeApps.defaultApplications，并在 activation 中把 ~/.nix-profile/share/applications/*.desktop 链接到 ~/.local/share/applications
  implication: 仓库具备“通过 Home Manager 覆盖 desktop entry 与 MIME 关联”的现成机制，适合承载 WPS wrapper 默认启动修复

- timestamp: 2026-04-12T00:19:00Z
  checked: nixgl-apps.nix wrapWithNixGL
  found: 非 wayland 平台包装默认注入 QT_QPA_PLATFORM=xcb，并同时注入 fcitx 环境与 nixGL 启动链
  implication: 现有 wrapper 机制已经支持“默认强制 XWayland/xcb 启动”的实现方向，无需修改 upstream 包本体

- timestamp: 2026-04-12T00:19:30Z
  checked: nixgl-apps.nix 中 wpsoffice/wps 关键字搜索
  found: 当前 app catalog 中未找到 WPS/wpsoffice 定义
  implication: WPS 尚未接入 repo-managed wrapper/catalog，当前默认行为缺少受控的 desktop entry 与 MIME 覆盖

- timestamp: 2026-04-12T00:23:00Z
  checked: nixgl-apps.nix apps catalog + export logic
  found: catalog 中现有 GUI 应用通过 standardApp/customApp/mkNixGLApp 渲染后，统一导出 packages、shellAliases、binScripts、desktopEntries、mimeAssociations；modules/nixgl-runtime.nix 再把这些暴露给 packages.nix、desktop-entries.nix、home-manager-commands.nix
  implication: 规划中的“repo-managed wrapper + 覆盖 desktop entry 与文件关联”与现有架构完全一致，是最小且架构匹配的修复路径
## Resolution

root_cause: 
fix: 规划方向已同步：不改 upstream wpsoffice-cn，本仓库后续应通过现有 nixgl app catalog 生成 WPS wrapper（默认 QT_QPA_PLATFORM=xcb / XWayland）并让 desktop entry 与 MIME 默认走 wrapper
verification: 
files_changed: []
