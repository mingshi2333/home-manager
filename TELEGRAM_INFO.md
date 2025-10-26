# Telegram Desktop 配置说明

## 已安装版本

**Telegram Desktop 6.2.3+** (来自 nixpkgs unstable)

## 功能特性

✅ **nixGL 包装** - GPU 硬件加速支持  
✅ **fcitx5 集成** - 中文输入法支持  
✅ **桌面快捷方式** - 可从应用菜单启动  
✅ **命令行启动** - 使用 `telegram` 或 `Telegram` 命令  

## 启动方式

### 1. 命令行启动
```bash
telegram
# 或
Telegram
# 或
~/.local/bin/telegram
```

### 2. 应用菜单启动
在应用启动器中搜索 "Telegram Desktop" 并点击启动

### 3. zsh 别名
已配置 shell 别名:
```bash
telegram  # → 启动 Telegram Desktop
```

## 配置位置

- **数据目录**: `~/.local/share/TelegramDesktop/`
- **配置文件**: `~/.config/TelegramDesktop/`
- **可执行文件**: 通过 nixGL 包装,位于 `/nix/store/...`

## 技术细节

### nixGL 包装
```nix
telegramPackage = pkgs.symlinkJoin {
  name = "telegram-desktop-nixgl";
  paths = [ pkgs.telegram-desktop ];
  # 使用 nixGL 提供 GPU 驱动支持
  # 设置 fcitx5 输入法环境变量
};
```

### 环境变量
自动设置以下环境变量:
- `GTK_IM_MODULE=fcitx`
- `QT_IM_MODULE=fcitx`
- `XMODIFIERS=@im=fcitx`
- `SDL_IM_MODULE=fcitx`

## 更新升级

### 更新 Telegram
```bash
cd ~/.config/home-manager
nix flake update
home-manager switch
```

### 检查可用版本
```bash
nix search nixpkgs telegram-desktop
```

## 卸载

如果需要移除 Telegram Desktop,编辑 `~/.config/home-manager/home.nix`:

```nix
# 注释掉或删除以下行
home.packages = with pkgs; [
  # telegramPackage  # <-- 注释掉这行
  ...
];
```

然后运行:
```bash
home-manager switch
```

## 故障排查

### 问题: Telegram 无法启动
**解决方案**:
```bash
# 检查 nixGL 是否正常
nixGL --version

# 查看详细错误信息
telegram 2>&1 | less
```

### 问题: 中文输入法不工作
**解决方案**:
1. 确保系统 fcitx5 正在运行: `ps aux | grep fcitx`
2. 重启 Telegram
3. 检查环境变量: `env | grep fcitx`

### 问题: GPU 加速不工作
**解决方案**:
```bash
# 检查 GPU 驱动
nvidia-smi  # 对于 NVIDIA GPU
# 或
glxinfo | grep "OpenGL"

# 重新生成 nixGL
cd ~/.config/home-manager
home-manager switch
```

## 与 AyuGram 的区别

| 特性 | Telegram Desktop | AyuGram |
|-----|------------------|---------|
| Ghost Mode | ❌ | ✅ |
| 官方支持 | ✅ | ❌ |
| 稳定性 | ✅ 高 | ⚠️ 中 |
| 更新频率 | ✅ 官方同步 | ⚠️ 需等待 |
| nixpkgs 可用性 | ✅ 总是可用 | ❌ 当前构建失败 |

## 相关链接

- [Telegram Desktop 官网](https://desktop.telegram.org/)
- [Telegram Desktop GitHub](https://github.com/telegramdesktop/tdesktop)
- [nixpkgs telegram-desktop](https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/instant-messengers/telegram/telegram-desktop/)
