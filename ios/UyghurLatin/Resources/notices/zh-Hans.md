# 第三方声明

本项目打包或衍生使用了以下开源成果。

## UyghurEdit++ / imla 词库

- 项目：https://github.com/gheyret/UyghurEditPP
- 相关拼写引擎：https://github.com/gheyret/UyghurSpell
- 使用文件：`uyghur_imla.txt`、`imla_xatatoghra.txt`
- 许可：MIT

## 《现代维吾尔文学语言正字词典》OCR 文本

- 项目：https://github.com/gheyret/imlalughet
- 许可：MIT

## 维吾尔多文字转换器（`umsc`）

- 项目：https://github.com/neouyghur/Uyghur-Multi-Script-Converter
- PyPI：https://pypi.org/project/umsc/
- 构建时将阿拉伯字母词条转换为维吾尔拉丁文（ULY）
- 许可：Apache License 2.0

## 维吾尔语维基百科（词频与二元组统计）

- 来源：https://ug.wikipedia.org/（条目转储，https://dumps.wikimedia.org/ugwiki/）
- 仅在构建时统计词频和相邻词频率；随应用分发的只有这些统计数字，不含条目正文
- 许可：CC BY-SA 4.0（https://creativecommons.org/licenses/by-sa/4.0/），© 维基百科贡献者

## 字母表参考

- 维吾尔拉丁字母（ULY），2008 修订（`ë`、`zh`，双字母 `ch/sh/zh/gh/ng`）

## 架构启发（未原文照搬）

- https://github.com/walkerbrown/latinum — 离线 n-gram 键盘思路
- https://github.com/NoerNova/ShanKeyboard-iOS — 候选栏分层思路
