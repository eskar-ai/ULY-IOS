export function normalizeULY(text: string): string {
  return text
    .replace(/É/g, 'Ë')
    .replace(/é/g, 'ë')
    .replace(/ʼ/g, "'")
    .replace(/\u2019/g, "'");
}

export function lookupKey(text: string): string {
  return normalizeULY(text).toLowerCase();
}

export function isWordChar(ch: string): boolean {
  if (!ch) {
    return false;
  }
  if (ch === "'" || ch === '\u2019' || ch === 'ʼ') {
    return true;
  }
  return /[A-Za-zÖÜËöüëÉé]/.test(ch);
}
