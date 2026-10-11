# Android — 打包 / 展示 / 更新 / 贡献 / 脚本 / 依赖

> 分支：`cursor/android-uly-keyboard-9edd` · **勿合入 main** 直至 release-ready。  
> 总览计划：Cloud Agent roadmap（Android / HarmonyOS / iOS 分栏）；本文件只约束 Android。

## 1. 打包（Package）

| 方式 | 说明 | 怎么做 |
|------|------|--------|
| Debug APK | 本地 / CI | `./scripts/build-debug.sh` |
| Release APK | 签名发布 | `./scripts/build-release.sh`（`ANDROID_RELEASE_STORE_FILE` 等） |
| AAB | Play Store（后期） | `./gradlew :app:bundleRelease` |
| GitHub Releases | 现阶段主分发 | 推送标签 `android-vX.Y.Z` → `.github/workflows/android-release.yml` |
| Play Store | 后期 | 不阻塞 Releases |

版本号：`app/build.gradle.kts` → `versionCode` / `versionName`。

发布说明草稿：`./scripts/package-release-notes.sh 0.1.0`

## 2. 展示（Display）

| 表面 | 内容 |
|------|------|
| Host App | 启用步骤、试用输入、lexicon 元信息、隐私一句 |
| IME UI | 候选栏 + ULY 键位 / 长按 |
| Pages `downloads.html` | Android 栏：状态 + 本分支源码；有 APK 后改 Releases CTA |
| README / PLATFORM | 安装与启用说明 |

固定站点（Pages）：`https://eskar-ai.github.io/ULY-IOS/downloads.html`

## 3. 更新（Update）

| 机制 | 做法 |
|------|------|
| 版本 bump | 改 `versionCode` / `versionName` |
| 用户更新 | Releases 手动下载；**无**强制检查、无埋点 |
| 词库 | `./scripts/sync-lexicon.sh` ← `data/generated/lexicon.json` |
| 可选后期 | Host 内「打开 GitHub Releases」（浏览器 Intent，IME 仍无网络权限） |

## 4. 贡献（Contribute）

| 入口 | 位置 |
|------|------|
| 平台指南 | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| 根指南 | 根 [`CONTRIBUTING.md`](../CONTRIBUTING.md)（平台表） |
| PR | 提向本 Android 分支；勿直接合 main |
| 欢迎 | 引擎单测、IME UX、四语文案、lexicon、打包脚本 |

## 5. 快捷脚本

```bash
cd android
chmod +x scripts/*.sh gradlew
./scripts/sync-lexicon.sh
./scripts/run-unit-tests.sh
./scripts/build-debug.sh
./scripts/build-release.sh
./scripts/package-release-notes.sh 0.1.0
```

CI：`.github/workflows/android-ci.yml`（仅本分支 / `android/**`）。

## 6. 依赖（Dependencies）

| 类别 | 项 | 备注 |
|------|----|------|
| 构建 | AGP 8.7、Kotlin 2.0、Gradle 8.9、JDK 17 | 根 `build.gradle.kts` / wrapper |
| App | AndroidX Core/AppCompat、Material、ConstraintLayout | `app/build.gradle.kts` |
| Engine | `org.json:json` | JVM 单测可解析 lexicon |
| 测试 | JUnit 4；Espresso + AndroidX Test | `uly-engine` unit / `app` androidTest |
| 词库工具 | 根 `tools/requirements.txt`（可选重建） | 与 iOS/鸿蒙共用源 |

**不引入**：广告、分析 SDK、IME 打字路径上的网络权限。

## 7. 与其他平台的边界

| 平台 | 分支 | 目录 |
|------|------|------|
| iOS / web | `main` | `ios/` `web/` |
| Android（本文件） | 本分支 | `android/` |
| HarmonyOS NEXT | `cursor/harmonyos-uly-keyboard-9edd` | `harmonyos/` |

引擎规格可对齐，**打包脚本、依赖、展示 CTA、更新渠道全部独立**。

## 发布检查清单

1. `sync-lexicon` + 版本 bump  
2. `./scripts/run-unit-tests.sh`；设备上 smoke IME  
3. 签名 APK → GitHub Release  
4. 更新本分支 `store/site/downloads.html` Android CTA → `releases/latest`  
5. 更新 draft PR；仍不 merge main  
