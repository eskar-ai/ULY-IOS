# Third-party notices

This project bundles or derives data from the following open-source works.

## UyghurEdit++ / imla lexicon

- Project: [gheyret/UyghurEditPP](https://github.com/gheyret/UyghurEditPP)
- Related spell engine: [gheyret/UyghurSpell](https://github.com/gheyret/UyghurSpell)
- Files used: `uyghur_imla.txt`, `imla_xatatoghra.txt`
- License: MIT

## Hazirqi Zaman Uyghur Edebiy Tilining Imla Lughiti (OCR text)

- Project: [gheyret/imlalughet](https://github.com/gheyret/imlalughet)
- License: MIT

## Uyghur Multi-Script Converter (`umsc`)

- Project: [neouyghur/Uyghur-Multi-Script-Converter](https://github.com/neouyghur/Uyghur-Multi-Script-Converter)
- PyPI: [umsc](https://pypi.org/project/umsc/)
- Used at build time to convert Arabic-script lemmas to Uyghur Latin Script
- License: Apache License 2.0

## Uyghur Wikipedia (word and bigram statistics)

- Source: [Uyghur Wikipedia](https://ug.wikipedia.org/) article dump from [dumps.wikimedia.org](https://dumps.wikimedia.org/ugwiki/)
- Used at build time (`tools/extract_wiki_corpus.py`) to count word and adjacent-word frequencies; only those counts are shipped, no article text
- License: [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/), © Wikipedia contributors

## Curated ULY phrase corpus

- File: [`data/corpus/uly_phrases.txt`](data/corpus/uly_phrases.txt)
- Purpose: offline bigram / next-word prediction seeds for the keyboard lexicon build
- License: project MIT (hand-authored phrases; not copied from copyrighted publications)

## Alphabet reference

- [Uyghur Latin alphabet (ULY)](https://en.wikipedia.org/wiki/Uyghur_Latin_alphabet) — 2008 revision (`ë`, `zh`, digraphs `ch/sh/zh/gh/ng`)

## Architecture inspiration (not copied verbatim)

- [walkerbrown/latinum](https://github.com/walkerbrown/latinum) — offline n-gram keyboard patterns
- [NoerNova/ShanKeyboard-iOS](https://github.com/NoerNova/ShanKeyboard-iOS) — suggestion-bar layering ideas
