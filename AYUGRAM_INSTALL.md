# AyuGram 安装指南

由于 AyuGram 在 nixpkgs unstable 中存在构建问题（Qt::CorePrivate 依赖），目前有以下几种替代方案：

## 方案 1: 使用官方 Telegram Desktop (最简单)

在 `home.nix` 中添加:
```nix
home.packages = with pkgs; [
  telegram-desktop
];
```

然后运行:
```bash
home-manager switch
```

## 方案 2: 从源码编译 AyuGram

需要手动编译，步骤较复杂。参考: https://github.com/AyuGram/AyuGramDesktop

## 方案 3: 等待上游修复

关注以下问题的进展:
- nixpkgs ayugram-desktop 包的 Qt6 依赖问题
- 可以定期运行 `nix-channel --update` 和 `home-manager switch` 来测试是否已修复

检查是否已修复:
```bash
nix-build '<nixpkgs>' -A ayugram-desktop
```

## 方案 4: 使用 64Gram (另一个 Telegram 客户端)

64Gram 是另一个流行的 Telegram 第三方客户端，在 nixpkgs 中可用:
```nix
home.packages = with pkgs; [
  tdesktop  # 或者 telegram-desktop
];
```

## 临时解决方案 (不推荐)

如果你一定要使用 AyuGram，可以尝试:
1. 使用 Docker/Podman 运行
2. 手动下载 Windows 版本并用 Wine 运行
3. 在虚拟机中使用 Arch Linux 的 AUR 包

---

**推荐**: 暂时使用官方 Telegram Desktop (方案 1)，等待 nixpkgs 修复后再切换回 AyuGram。
