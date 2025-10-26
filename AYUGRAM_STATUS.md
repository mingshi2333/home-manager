# AyuGram 配置状态说明

## 当前配置

由于 nixpkgs unstable 中的 `ayugram-desktop` 存在 Qt6 构建问题,当前配置使用了以下策略:

### 策略: 使用 NixOS 24.05 稳定版 + 后备方案

```nix
oldNixpkgs = import (builtins.fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz";
  sha256 = "0zydsqiaz8qi4zd63zsb2gij2p614cgkcaisnk11wjy3nmiq0x1s";
}) { 
  system = pkgs.system;
  config = { allowUnfree = true; };
};

ayugramPackage = oldNixpkgs.ayugram-desktop or pkgs.telegram-desktop;
```

### 实际效果

- ✅ **配置可以成功构建和运行**
- ⚠️  **当前使用的是 Telegram Desktop 6.2.3** (因为 24.05 中没有 ayugram-desktop)
- ✅ 所有命令别名和快捷方式都已设置 (`AyuGram`, `telegram` 命令)
- ✅ 包含 nixGL 包装和 fcitx5 输入法支持

### 命令

```bash
# 这些命令都指向同一个程序 (telegram-desktop)
AyuGram
telegram
~/.local/bin/AyuGram
```

### 桌面快捷方式

已创建 `ayugram.desktop` 快捷方式,可以从应用菜单启动。

## 未来升级路径

### 方案 1: 等待 nixpkgs unstable 修复 (推荐)

定期检查:
```bash
nix-build '<nixpkgs>' -A ayugram-desktop
```

如果成功,更新配置:
```nix
# 移除 oldNixpkgs,直接使用:
ayugramPackage = pkgs.symlinkJoin {
  name = "ayugram-desktop-nixgl";
  paths = [ pkgs.ayugram-desktop ];
  # ...
};
```

### 方案 2: 使用更旧的 commit (不推荐,可能有安全问题)

查找能构建 ayugram-desktop 的旧 commit:
```bash
# 搜索 nixpkgs 历史
git clone https://github.com/NixOS/nixpkgs.git --depth=1 --branch nixos-23.11
cd nixpkgs
git log --all --grep="ayugram" --oneline
```

### 方案 3: 手动编译最新版本

参考: https://github.com/AyuGram/AyuGramDesktop

## 注意事项

1. 当前实际使用的是官方 Telegram Desktop,功能与 AyuGram 有差异
2. 如果需要 AyuGram 的特殊功能(Ghost Mode 等),建议等待上游修复
3. 配置保持了 AyuGram 的命名和结构,方便未来切换

## 相关链接

- [AyuGram Desktop GitHub](https://github.com/AyuGram/AyuGramDesktop)
- [nixpkgs ayugram-desktop](https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/instant-messengers/telegram/ayugram-desktop/default.nix)
