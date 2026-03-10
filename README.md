# Home Manager Configuration

## 架构说明

配置已重构为模块化架构：

- `home.nix` - 精简后的组合入口
- `modules/nixgl-runtime.nix` - nixGL/NVIDIA 运行时数据与内部接口
- `modules/home-manager-commands.nix` - `hms`/`hmu`/`hmr` 与 NVIDIA 元数据刷新命令
- `profiles/base.nix` - 基础环境导入
- `profiles/gui.nix` - GUI 相关模块导入
- `profiles/packages.nix` - 包管理模块导入
- `nixgl-apps.nix` - nixGL 应用管理模块
- `nixgl-noimpure.nix` - nixGL 包装器

## 添加新应用

### 1. 标准路径: 在 `nixgl-apps.nix` 添加一条 catalog entry

现在所有应用都在 `nixgl-apps.nix` 里注册；常规 nixGL 应用优先使用标准 helper：

```nix
myapp = standardApp {
  pkg = pkgs.myapp;
  enable = true;                        # 可选，默认 true
  platform = "wayland";                # 可选，默认 xcb
  categories = [ "Utility" ];
  mimeTypes = [ "x-scheme-handler/myapp" ];
  execArgs = "%U";
  # 需要时再显式覆盖这些默认值:
  # desktopName = "My App (nixGL)";
  # comment = "My App (nixGL)";
  # icon = "myapp";
};
```

标准 entry 会自动进入默认启用集合；`local.nixgl.enabledApps` 反映当前 catalog 中启用的应用 id。

### 2. 特殊情况: 仍然留在同一个 catalog，但用更显式的 helper

如果应用需要额外权限、包装名与 catalog id 不一致、desktop basename 不一致，或有其他特殊逻辑，仍然放在 `nixgl-apps.nix`，但改用更显式的 helper：

- `standardApp { name = "ayugram-desktop"; ... }` 适合“仍是 nixGL app，但命名不标准”的场景
- `customApp { ... }` 适合 `pkexec`、自定义脚本、手写 desktop entry 这类场景
- `mkNixGLApp` 和 `wrapWithNixGL` 仍保留，供需要最低层控制时直接使用

### 3. 自动生成的内容

添加应用后，系统会自动生成：

- ✅ nixGL 包装的可执行文件
- ✅ Shell 别名（zsh）
- ✅ `~/.local/bin/` 中的启动脚本
- ✅ XDG desktop entry
- ✅ MIME 类型关联

### 4. 应用配置

运行 `home-manager switch --impure` 或使用别名 `hms`

## 示例

### Wayland 应用（Electron）

```nix
vscode = standardApp {
  pkg = pkgs.vscode;
  name = "code";  # 仅当 wrapper 名与 catalog key 不同时才需要
  platform = "wayland";
  desktopName = "Visual Studio Code";
  comment = "Code Editor (nixGL)";
  categories = [ "Development" "IDE" ];
  icon = "vscode";
};
```

### 命名不标准但仍属标准 nixGL 路径

```nix
ayugram = standardApp {
  pkg = pkgs.ayugram-desktop;
  name = "ayugram-desktop";
  binary = "AyuGram";
  aliases = [ "Ayugram" "ayugram" ];
  platform = "wayland";
  mimeTypes = [ "x-scheme-handler/tg" ];
  dbusService = "org.ayugram.desktop.service";
};
```

### 自定义脚本型应用

```nix
lenovo-legion = customApp {
  shellAliases = {
    legionpk = "lenovo-legion-pkexec";
  };
  desktopId = "lenovo-legion-gui-pkexec";
  desktopEntry = {
    name = "Lenovo Legion Control (pkexec)";
    exec = "${config.home.homeDirectory}/.local/bin/lenovo-legion-gui-pkexec";
    terminal = false;
    type = "Application";
    categories = [ "Utility" "System" ];
    icon = "computer";
  };
};
```

## 优化点

### ✅ 已实现

1. **模块化架构** - 应用定义与主配置分离
2. **自动化生成** - 一次定义，自动生成所有必需文件
3. **DRY 原则** - 消除重复代码（从 ~500 行减少到 ~120 行）
4. **统一环境变量** - fcitx 配置通过共享 helper 管理
5. **自动 MIME 关联** - 声明式 MIME 类型注册
6. **冲突处理** - 使用 buildEnv 处理二进制文件冲突

### 🎯 最佳实践

- 使用 `platform = "wayland"` 为 Electron 应用启用 Wayland 支持
- 使用 `platform = "xcb"` 为 Qt/X11 应用
- 为 URL scheme handlers 添加 `mimeTypes` 和 `execArgs = "-- %u"`
- 为文件关联添加 `execArgs = "%F"` 或 `"%U"`

## 便捷命令

```bash
hms   # 刷新 NVIDIA 元数据后执行 home-manager switch --impure
hmu   # 刷新 NVIDIA 元数据、更新 flake 后执行 switch --impure
hmr   # 回滚到上一个版本（--impure --rollback）
```

## 故障排除

### 网络连接问题

如果遇到 SSL 连接错误，稍后重试：
```bash
home-manager switch --impure
```

### 应用无法启动

检查日志：
```bash
journalctl --user -xe
```

### Desktop entry 未显示

刷新缓存：
```bash
update-desktop-database ~/.local/share/applications
kbuildsycoca6  # KDE
```

## 桌面条目去重与刷新

Home Manager 会自动：
- 将 `~/.nix-profile/share/applications` 下的 .desktop 链接到 `~/.local/share/applications`
- 刷新 desktop 数据库与 KDE 缓存
- 按应用列表自动去重（默认包含 nixglApps 中的应用名、telegram 相关前缀）

如需新增去重前缀，可在 `modules/nixgl-runtime.nix` 的 `dedupApps` 列表中追加，例如：
```nix
dedupApps = (builtins.attrNames nixglApps.desktopEntries)
  ++ [ "org.telegram.desktop" "telegram" "myapp-prefix" ];
```
去重逻辑会删除非 Nix profile 来源的同名/前缀 `.desktop`，避免菜单重复。无需手工清理。
