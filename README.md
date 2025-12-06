# Home Manager Configuration

## 架构说明

配置已重构为模块化架构：

- `home.nix` - 主配置文件
- `nixgl-apps.nix` - nixGL 应用管理模块
- `nixgl-noimpure.nix` - nixGL 包装器

## 添加新应用

### 1. 在 nixgl-apps.nix 中添加应用定义

编辑 `nixgl-apps.nix`，在 `apps` 属性集中添加：

```nix
myapp = mkNixGLApp {
  pkg = pkgs.myapp;                    # 包名
  name = "myapp";                      # 主命令名
  binary = "MyApp";                    # 可选：原始二进制文件名（如果与 name 不同）
  platform = "wayland";                # "wayland" 或 "xcb"
  aliases = [ "myapp-alias" ];         # 可选：命令别名列表
  extraFlags = [ "--flag" ];           # 可选：额外的命令行参数
  extraEnv = { VAR = "value"; };       # 可选：额外的环境变量
  desktopName = "My App";              # 桌面显示名称
  comment = "My App (nixGL)";          # 应用描述
  categories = [ "Utility" ];          # 桌面分类
  icon = "myapp";                      # 图标名称
  mimeTypes = [ "x-scheme-handler/myapp" ];  # 可选：MIME 类型关联
  execArgs = "%U";                     # 可选：desktop entry 的额外参数
};
```

### 2. 自动生成的内容

添加应用后，系统会自动生成：

- ✅ nixGL 包装的可执行文件
- ✅ Shell 别名（zsh）
- ✅ `~/.local/bin/` 中的启动脚本
- ✅ XDG desktop entry
- ✅ MIME 类型关联

### 3. 应用配置

运行 `home-manager switch` 或使用别名 `hms`

## 示例

### Wayland 应用（Electron）

```nix
vscode = mkNixGLApp {
  pkg = pkgs.vscode;
  name = "code";
  platform = "wayland";
  desktopName = "Visual Studio Code";
  comment = "Code Editor (nixGL)";
  categories = [ "Development" "IDE" ];
  icon = "vscode";
};
```

### X11/Qt 应用

```nix
telegram = mkNixGLApp {
  pkg = pkgs.telegram-desktop;
  name = "telegram-desktop";
  binary = "Telegram";
  aliases = [ "telegram" ];
  platform = "xcb";
  desktopName = "Telegram Desktop";
  comment = "Telegram Desktop (nixGL)";
  categories = [ "Network" "InstantMessaging" ];
  icon = "telegram";
  mimeTypes = [ "x-scheme-handler/tg" ];
  execArgs = "-- %u";
};
```

### 带 MIME 类型的应用

```nix
readest = mkNixGLApp {
  pkg = pkgs.readest;
  name = "readest";
  platform = "wayland";
  desktopName = "Readest";
  comment = "Ebook Reader (nixGL)";
  categories = [ "Office" "Utility" ];
  icon = "readest";
  mimeTypes = [
    "application/epub+zip"
    "application/pdf"
  ];
  execArgs = "%F";
};
```

## 优化点

### ✅ 已实现

1. **模块化架构** - 应用定义与主配置分离
2. **自动化生成** - 一次定义，自动生成所有必需文件
3. **DRY 原则** - 消除重复代码（从 ~500 行减少到 ~120 行）
4. **统一环境变量** - fcitx 配置集中管理
5. **自动 MIME 关联** - 声明式 MIME 类型注册
6. **冲突处理** - 使用 buildEnv 处理二进制文件冲突

### 🎯 最佳实践

- 使用 `platform = "wayland"` 为 Electron 应用启用 Wayland 支持
- 使用 `platform = "xcb"` 为 Qt/X11 应用
- 为 URL scheme handlers 添加 `mimeTypes` 和 `execArgs = "-- %u"`
- 为文件关联添加 `execArgs = "%F"` 或 `"%U"`

## 便捷命令

```bash
hms   # home-manager switch
hmu   # 更新 flake 并 switch
hmr   # 回滚到上一个版本
```

## 故障排除

### 网络连接问题

如果遇到 SSL 连接错误，稍后重试：
```bash
home-manager switch
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

如需新增去重前缀，可在 `home.nix` 的 `dedupApps` 列表中追加，例如：
```nix
  dedupApps = (builtins.attrNames nixglApps.desktopEntries)
    ++ [ "org.telegram.desktop" "telegram" "myapp-prefix" ];
```
去重逻辑会删除非 Nix profile 来源的同名/前缀 .desktop，避免菜单重复。无需手工清理。*** End Patch"));
