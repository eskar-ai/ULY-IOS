# HarmonyOS NEXT — 打包 / 展示 / 更新 / 贡献 / 脚本 / 依赖

> 分支：`cursor/harmonyos-uly-keyboard-9edd` · **勿合入 main** 直至 release-ready。  
> 总览计划：仓库外 roadmap（Android / HarmonyOS / iOS 分栏）；本文件只约束鸿蒙。

## 1. 打包（Package）

| 方式 | 说明 | 怎么做 |
|------|------|--------|
| Debug HAP | 本地调试 | DevEco → Build Hap(s) |
| Release HAP | 正式签名 | DevEco 签名配置 + `./scripts/build-hap-notes.sh X.Y.Z` |
| AppGallery Connect 测试 | 推荐测试分发 | 不假设用户能裸装 HAP |
| GitHub Releases | 附说明 + 测试通道链接 | 发布说明用 notes 脚本生成 |
| AppGallery 正式上架 | 后期 | 就绪后改 Pages CTA |

版本号：`AppScope/app.json5` → `versionCode` / `versionName`。

产物命名建议：`uyghur-uly-keyboard-harmonyos-vX.Y.Z.hap`（或商店包名以 AGC 为准）。

## 2. 展示（Display）

| 表面 | 内容 |
|------|------|
| `entry` Host | 启用说明、试用输入、隐私一句 |
| IME Panel | 候选栏 + ULY 键位 / 长按层 |
| Pages `downloads.html` | 鸿蒙栏：状态 + 源码分支；有包后换测试/商店 CTA |
| 本目录 README / PLATFORM | DevEco 打开与启用路径 |

固定站点（Pages）：`https://eskar-ai.github.io/ULY-IOS/downloads.html`

## 3. 更新（Update）

| 机制 | 做法 |
|------|------|
| 版本 bump | 改 `AppScope/app.json5` |
| 用户更新 | AppGallery / 测试通道；**无**静默强更、无埋点 |
| 词库 | `./scripts/sync-lexicon.sh` ← `data/generated/lexicon.json` |
| 发布说明 | `./scripts/build-hap-notes.sh X.Y.Z` |

## 4. 贡献（Contribute）

| 入口 | 位置 |
|------|------|
| 平台指南 | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| 根指南 | 根 [`CONTRIBUTING.md`](../CONTRIBUTING.md)（平台表） |
| PR | 提向本 HarmonyOS 分支；勿直接合 main |
| 欢迎 | ArkTS 引擎、IMEKit 接线、Hypium、四语文案、lexicon |

## 5. 快捷脚本

```bash
cd harmonyos
chmod +x scripts/*.sh
./scripts/sync-lexicon.sh
./scripts/run-unit-tests.sh          # Node smoke（CI / 无 DevEco）
./scripts/build-hap-notes.sh 0.1.0
# Hypium + HAP 构建：DevEco Studio
```

CI：`.github/workflows/harmonyos-ci.yml`（仅本分支 / `harmonyos/**`）。

## 6. 依赖（Dependencies）

| 类别 | 项 | 备注 |
|------|----|------|
| IDE/SDK | DevEco Studio、HarmonyOS NEXT API 12+ | 构建 HAP 必需 |
| Kit | AbilityKit、IMEKit、ArkUI、ArkTS `util` | IME 扩展 |
| 包管理 | ohpm · `oh-package.json5` | `uly_engine` file HAR |
| 测试 | `@ohos/hypium`；CI Node smoke | 设备测在 DevEco |
| 词库工具 | 根 `tools/requirements.txt`（可选重建） | 与 iOS/Android 共用源 |

**不引入**：广告、分析 SDK、打字路径上的网络权限。

## 7. 与其他平台的边界

| 平台 | 分支 | 目录 |
|------|------|------|
| iOS / web | `main` | `ios/` `web/` |
| Android | `cursor/android-uly-keyboard-9edd` | `android/` |
| HarmonyOS（本文件） | 本分支 | `harmonyos/` |

引擎规格可对齐，**打包脚本、依赖、展示 CTA、更新渠道全部独立**，不在本分支提交 `android/` 大改，反之亦然。

## 性能

见 [`PERFORMANCE.md`](PERFORMANCE.md)（联想 debounce、拼写短路、词库异步加载）。

## 发布检查清单

1. `sync-lexicon` + 版本 bump  
2. `./scripts/run-unit-tests.sh` + DevEco Hypium/ohosTest  
3. 签名 HAP → 测试通道 / Releases 说明  
4. 更新本分支 `store/site/downloads.html` 鸿蒙 CTA  
5. 更新 draft PR；仍不 merge main  
