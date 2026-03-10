# Home Manager 使用指南

## 自动功能

### 自动刷新 Desktop 文件
每次运行 `home-manager switch` 时会自动:
1. 复制 `~/.nix-profile/share/applications/*.desktop` 到 `~/.local/share/applications/`
2. 运行 `update-desktop-database` 刷新数据库
3. 运行 `kbuildsycoca6` 刷新 KDE 菜单缓存

这意味着你不需要手动复制 desktop 文件或刷新 KDE 菜单了!

## 添加 nixGL 应用

### 统一 catalog 路径: 在 `nixgl-apps.nix` 添加一条 entry

现在所有应用都统一注册在 `nixgl-apps.nix`，常规场景不需要再重复写 catalog id。

- 常规 nixGL GUI 应用优先使用 `standardApp`
- 命名不标准但仍属 nixGL 包装的应用，仍可用 `standardApp` 并显式覆盖 `name` / `binary`
- 需要 `pkexec`、自定义脚本或手写 desktop entry 的应用，使用 `customApp`

```nix
myapp = standardApp {
  pkg = pkgs.myapp;
  categories = [ "Utility" ];
};
```

- `enable ? true`，默认会被纳入 `local.nixgl.enabledApps`
- `local.nixgl.enabledApps` 现在表示当前 catalog 中启用的应用 id
- 生成的 desktop entry、shell alias、`~/.local/bin` wrapper 和 MIME 关联仍由运行时统一导出

### 自定义 catalog entry

如果应用需要 `pkexec`、额外系统集成，或 wrapper 名称不能按标准规则对齐，就继续留在 `nixgl-apps.nix`，但改用显式 helper。

- `standardApp { name = "ayugram-desktop"; ... }` 适合命名不规则但仍属标准 nixGL 包装的应用
- `customApp { ... }` 适合 `pkexec` 或脚本型应用
- 需要时仍可直接使用 `mkNixGLApp`

## 便捷命令别名

重新启动终端或运行 `source ~/.zshrc` 后,你可以使用以下别名:

### `hms` - Home Manager Switch
快速切换到新配置:
```bash
hms
```
等同于:
```bash
cd ~/.config/home-manager
# refresh nvidia/version and nvidia/hash if needed
home-manager switch --impure
```

### `hmu` - Home Manager Update
更新 flake 输入并切换到新配置:
```bash
hmu
```
等同于:
```bash
cd ~/.config/home-manager
# refresh nvidia/version and nvidia/hash if needed
nix flake update
home-manager switch --impure
```

这会:
1. 更新 `flake.lock` 中的所有依赖(nixpkgs, home-manager 等)
2. 安装最新版本的软件包
3. 应用新配置

### `hmr` - Home Manager Rollback
回滚到上一个配置:
```bash
hmr
```
等同于:
```bash
cd ~/.config/home-manager && home-manager switch --impure --rollback
```

## 推荐工作流程

### 日常使用
```bash
# 修改 `home.nix`、`modules/nixgl-runtime.nix` 或其他模块后应用配置
hms

# 定期更新所有软件(例如每周一次)
hmu
```

### 如果更新后有问题
```bash
# 立即回滚到上一个版本
hmr
```

## 注意事项

1. **自动更新**: `hmu` 会更新所有包到最新版本,可能导致破坏性变更
2. **版本锁定**: 如果你想锁定特定版本,不要运行 `hmu`,只运行 `hms`
3. **NVIDIA 元数据**: `hms` 和 `hmu` 会在切换前尝试刷新 `nvidia/version` 与 `nvidia/hash`
4. **回滚**: `hmr` 只能回滚一代,如果需要回滚多代,使用:
   ```bash
   home-manager generations  # 查看所有代数
   home-manager switch --to-generation <number>
   ```

## Wayland 问题修复

Telegram 和其他 Qt 应用在 Wayland 下通过 `QT_QPA_PLATFORM=xcb` 强制使用 XWayland,确保在 KDE Wayland 和 X11 环境下都能正常工作。
