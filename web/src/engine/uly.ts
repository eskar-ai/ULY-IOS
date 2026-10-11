export function normalizeULY(text: string): string {
  return text
    .replaceAll("É", "Ë")
    .replaceAll("é", "ë")
    .replaceAll("ʼ", "'")
    .replaceAll("\u2019", "'");
}

export function lookupKey(text: string): string {
  return normalizeULY(text).toLowerCase();
}

export function isWordChar(ch: string): boolean {
  if (!ch) return false;
  if (ch === "'" || ch === "\u2019" || ch === "ʼ") return true;
  return /[A-Za-zÖÜËöüëÉé]/.test(ch);
}
