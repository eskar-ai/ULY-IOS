# iOS — 打包 / 展示 / 更新 / 贡献 / 脚本 / 依赖

> 主线：`main`（或本 PR 分支合入 `main`）。  
> **不要**把未就绪的 `android/` / `harmonyos/` 目录合进 `main`。

## 1. 打包（Package）

| 方式 | 说明 | 怎么做 |
|------|------|--------|
| XcodeGen + Xcode | 本地调试 / Archive | `./scripts/generate.sh` → open project |
| Ad Hoc / Development | 设备安装 | Xcode Run / Organizer |
| TestFlight | 外测 | `./scripts/archive-example.sh` + Transporter |
| App Store | 正式上架 | 见 [`../store/CHECKLIST.md`](../store/CHECKLIST.md) |

版本与上架材料：`store/`（listing、隐私、截图清单）。

## 2. 展示（Display）

| 表面 | 内容 |
|------|------|
| Host App | 启用步骤、隐私、Credits、UI 四语 |
| Keyboard Extension | 候选栏 + ULY 键位/长按/主题 |
| Pages | `index` / `learn` / `privacy` / `support` / **`downloads`** |
| Web demo | https://eskar-ai.github.io/ULY-IOS/demo/ |

Downloads：https://eskar-ai.github.io/ULY-IOS/downloads.html（Pages 随 `main` 的 `store/site/**` 部署）

## 3. 更新（Update）

| 机制 | 做法 |
|------|------|
| App 版本 | Xcode / `project.yml` marketing version |
| 用户更新 | App Store / TestFlight |
| 词库 | `../tools/build_lexicon.py` → `UyghurLatinKeyboard/Resources/` |
| Demo | Pages workflow 构建 `web/` |

不做强制检查或埋点。

## 4. 贡献（Contribute）

| 入口 | 位置 |
|------|------|
| 平台指南 | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| 根指南 | [`../CONTRIBUTING.md`](../CONTRIBUTING.md) |
| PR | 指向 `main`；勿夹带未完成 Android/鸿蒙树 |
| 欢迎 | 引擎、键盘 UX、四语文案、lexicon、站点 |

## 5. 快捷脚本

```bash
cd ios
./scripts/sync-lexicon.sh
./scripts/generate.sh
./scripts/archive-example.sh   # 需本机签名配置
```

Web / lexicon（仓库根）：

```bash
cd web && npm ci && npm run build
python3 -m pip install -r tools/requirements.txt && python3 tools/build_lexicon.py
```

## 6. 依赖（Dependencies）

| 类别 | 项 | 备注 |
|------|----|------|
| IDE | macOS + Xcode 15+ | 真机/模拟器 |
| 工程 | XcodeGen（`project.yml`） | 生成 `.xcodeproj` |
| 引擎 | SwiftPM `Package.swift` → `Sources/UyghurLatinKit` | 与 web TS 规格对齐 |
| Web demo | npm / Vite / TypeScript | `web/` |
| 词库 | `tools/requirements.txt`（`umsc` 等） | 输出 `lexicon.json` |

**不引入**：广告、分析、Full Access（默认 `RequestsOpenAccess = false`）。

## 与其他平台的边界

| 平台 | 分支 | 目录 |
|------|------|------|
| iOS / web（本文件） | `main` | `ios/` `web/` `store/site/` |
| Android | `cursor/android-uly-keyboard-9edd` | `android/` |
| HarmonyOS NEXT | `cursor/harmonyos-uly-keyboard-9edd` | `harmonyos/` |

## 性能

见 [`PERFORMANCE.md`](PERFORMANCE.md)（异步词库、debounce 联想、拼写短路、上下文裁剪、suggestion cache）。

引擎单测（Mac）：

```bash
swift test --package-path .
```

## 发布检查清单

1. `sync-lexicon` + XcodeGen  
2. 模拟器/真机启用键盘；测建议与长按（确认无按键卡顿）  
3. Archive → TestFlight / App Store（`store/CHECKLIST.md`）  
4. 确认 Pages `downloads.html` iOS 区块文案正确  
