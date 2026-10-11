# Third-party notices

This project bundles or derives data from the following open-source works.

## UyghurEdit++ / imla lexicon

- Project: https://github.com/gheyret/UyghurEditPP
- Related spell engine: https://github.com/gheyret/UyghurSpell
- Files used: `uyghur_imla.txt`, `imla_xatatoghra.txt`
- License: MIT

## Hazirqi Zaman Uyghur Edebiy Tilining Imla Lughiti (OCR text)

- Project: https://github.com/gheyret/imlalughet
- License: MIT

## Uyghur Multi-Script Converter (`umsc`)

- Project: https://github.com/neouyghur/Uyghur-Multi-Script-Converter
- PyPI: https://pypi.org/project/umsc/
- Used at build time to convert Arabic-script lemmas to Uyghur Latin Script
- License: Apache License 2.0

## Uyghur Wikipedia (word and bigram statistics)

- Source: https://ug.wikipedia.org/ (article dump, https://dumps.wikimedia.org/ugwiki/)
- Used at build time to count word and adjacent-word frequencies; only those counts are shipped, no article text
- License: CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/), © Wikipedia contributors

## Alphabet reference

- Uyghur Latin alphabet (ULY), 2008 revision (`ë`, `zh`, digraphs `ch/sh/zh/gh/ng`)

## Architecture inspiration (not copied verbatim)

- https://github.com/walkerbrown/latinum — offline n-gram keyboard patterns
- https://github.com/NoerNova/ShanKeyboard-iOS — suggestion-bar layering ideas
