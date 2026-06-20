# DalamudPlugins

FF14 国服 XIVLauncherCN 第三方插件仓库。

## 使用方法

在 XIVLauncherCN 的 Dalamud 设置中添加第三方仓库 URL：

```
https://raw.githubusercontent.com/ijnokmsc/DalamudPlugins/main/pluginmaster.json
```

## 插件列表

| 插件 | 版本 | 描述 |
|------|------|------|
| **CraftFlow** | 0.2.3.0 | FF14生产辅助 - BOM展开/采集推送/一键制作 |
| **SilverDasher** | 0.1.0.0 | 跨服猎怪与 FATE 播报 |

## 仓库结构

```
DalamudPlugins/
├── pluginmaster.json    # 插件列表（Dalamud 读取此文件）
├── icons/               # 插件图标
├── .github/workflows/   # CI/CD 自动构建发布
└── README.md
```

## 自行构建

本仓库的 GitHub Actions 会自动构建并发布插件。

插件源码：
- [CraftFlow](https://github.com/ijnokmsc/CraftFlow)
- [SilverDasher](https://github.com/ijnokmsc/SilverDasher)
