import "./style.css";
import { LexiconStore, SuggestionEngine, isWordChar, lookupKey } from "./engine";

const editor = document.querySelector<HTMLTextAreaElement>("#editor")!;
const statusEl = document.querySelector<HTMLElement>("#status")!;
const candidatesEl = document.querySelector<HTMLElement>("#candidates")!;
const keyboardEl = document.querySelector<HTMLElement>("#keyboard")!;

type KeyDef =
  | { type: "char"; label: string; insert?: string; longPress?: string[] }
  | { type: "action"; action: string; label: string; wide?: boolean; space?: boolean };

const LETTER_ROWS: KeyDef[][] = [
  [
    { type: "char", label: "q", longPress: ["Q"] },
    { type: "char", label: "w", longPress: ["W"] },
    { type: "char", label: "e", longPress: ["ë", "é", "E", "Ë"] },
    { type: "char", label: "r", longPress: ["R"] },
    { type: "char", label: "t", longPress: ["T"] },
    { type: "char", label: "y", longPress: ["Y"] },
    { type: "char", label: "u", longPress: ["ü", "U", "Ü"] },
    { type: "char", label: "i", longPress: ["I"] },
    { type: "char", label: "o", longPress: ["ö", "O", "Ö"] },
    { type: "char", label: "p", longPress: ["P"] },
  ],
  [
    { type: "char", label: "a", longPress: ["A"] },
    { type: "char", label: "s", longPress: ["sh", "S"] },
    { type: "char", label: "d", longPress: ["D"] },
    { type: "char", label: "f", longPress: ["F"] },
    { type: "char", label: "g", longPress: ["gh", "G"] },
    { type: "char", label: "h", longPress: ["H"] },
    { type: "char", label: "j", longPress: ["J"] },
    { type: "char", label: "k", longPress: ["K"] },
    { type: "char", label: "l", longPress: ["L"] },
    { type: "char", label: "'", longPress: ["'"] },
  ],
  [
    { type: "action", action: "shift", label: "⇧", wide: true },
    { type: "char", label: "z", longPress: ["zh", "Z"] },
    { type: "char", label: "x", longPress: ["X"] },
    { type: "char", label: "c", longPress: ["ch", "C"] },
    { type: "char", label: "v", longPress: ["V"] },
    { type: "char", label: "b", longPress: ["B"] },
    { type: "char", label: "n", longPress: ["ng", "N"] },
    { type: "char", label: "m", longPress: ["M"] },
    { type: "action", action: "backspace", label: "⌫", wide: true },
  ],
  [
    { type: "action", action: "symbols", label: "123", wide: true },
    { type: "action", action: "uly", label: "ëöü", wide: true },
    { type: "action", action: "space", label: "boshluq", space: true },
    { type: "action", action: "return", label: "return", wide: true },
  ],
];

const SYMBOL_ROWS: KeyDef[][] = [
  "1234567890".split("").map((c) => ({ type: "char" as const, label: c })),
  "-/:;()$&@\"".split("").map((c) => ({ type: "char" as const, label: c })),
  [
    { type: "action", action: "letters", label: "ABC", wide: true },
    ...(".,?!'".split("").map((c) => ({ type: "char" as const, label: c }))),
    { type: "action", action: "backspace", label: "⌫", wide: true },
  ],
  [
    { type: "action", action: "letters", label: "ABC", wide: true },
    { type: "action", action: "space", label: "boshluq", space: true },
    { type: "action", action: "return", label: "return", wide: true },
  ],
];

const ULY_ROWS: KeyDef[][] = [
  [
    { type: "char", label: "ë" },
    { type: "char", label: "ö" },
    { type: "char", label: "ü" },
    { type: "char", label: "Ë" },
    { type: "char", label: "Ö" },
    { type: "char", label: "Ü" },
    { type: "char", label: "ch" },
    { type: "char", label: "sh" },
    { type: "char", label: "zh" },
    { type: "char", label: "gh" },
  ],
  [
    { type: "char", label: "ng" },
    { type: "char", label: "'" },
    { type: "char", label: "-" },
    { type: "char", label: "," },
    { type: "char", label: "." },
    { type: "char", label: "?" },
    { type: "char", label: "!" },
    { type: "action", action: "backspace", label: "⌫", wide: true },
  ],
  [
    { type: "action", action: "letters", label: "ABC", wide: true },
    { type: "action", action: "space", label: "boshluq", space: true },
    { type: "action", action: "return", label: "return", wide: true },
  ],
];

let engine: SuggestionEngine | null = null;
let shift = false;
let layer: "letters" | "symbols" | "uly" = "letters";
let longPressTimer: number | null = null;

function setStatus(text: string, kind: "ready" | "error" | "" = "") {
  statusEl.textContent = text;
  statusEl.className = `status ${kind}`.trim();
}

function getContext(): { partial: string; previous: string | null } {
  const value = editor.value;
  const caret = editor.selectionStart ?? value.length;
  let i = caret;
  while (i > 0 && isWordChar(value[i - 1]!)) i--;
  const partial = value.slice(i, caret);
  let j = i;
  while (j > 0 && /\s/.test(value[j - 1]!)) j--;
  let k = j;
  while (k > 0 && isWordChar(value[k - 1]!)) k--;
  const previous = k < j ? lookupKey(value.slice(k, j)) : null;
  return { partial, previous };
}

function renderCandidates() {
  if (!engine) {
    candidatesEl.innerHTML = "";
    return;
  }
  const { partial, previous } = getContext();
  const result = engine.suggest(partial, previous, 8);
  candidatesEl.innerHTML = "";
  result.candidates.forEach((word, idx) => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = `candidate${idx === 0 ? " primary" : ""}${result.isMisspelled ? " misspelled" : ""}`;
    btn.textContent = word;
    btn.addEventListener("click", () => applyCandidate(word, partial));
    candidatesEl.appendChild(btn);
  });
  if (result.mode === "correction" && result.candidates.length) {
    setStatus(`Imla: «${partial}» → ${result.candidates.slice(0, 3).join(", ")}`, "ready");
  } else if (engine.meta) {
    setStatus(
      `Offline · ${engine.meta.wordCount.toLocaleString()} söz · ${engine.meta.script}`,
      "ready",
    );
  }
}

function applyCandidate(word: string, partial: string) {
  const value = editor.value;
  const caret = editor.selectionStart ?? value.length;
  const start = caret - partial.length;
  const before = value.slice(0, start);
  const after = value.slice(caret);
  const insert = partial.length ? word : word + " ";
  const needsSpace = partial.length > 0;
  editor.value = before + insert + (needsSpace ? " " : "") + after;
  const pos = (before + insert + (needsSpace ? " " : "")).length;
  editor.setSelectionRange(pos, pos);
  engine?.learnSelection(word);
  shift = false;
  renderKeyboard();
  renderCandidates();
  editor.focus();
}

function insertText(text: string) {
  const value = editor.value;
  const start = editor.selectionStart ?? value.length;
  const end = editor.selectionEnd ?? value.length;
  editor.value = value.slice(0, start) + text + value.slice(end);
  const pos = start + text.length;
  editor.setSelectionRange(pos, pos);
  if (shift && text.length === 1 && /[a-zëöü]/.test(text)) {
    shift = false;
    renderKeyboard();
  }
  renderCandidates();
  editor.focus();
}

function backspace() {
  const value = editor.value;
  const start = editor.selectionStart ?? value.length;
  const end = editor.selectionEnd ?? value.length;
  if (start !== end) {
    editor.value = value.slice(0, start) + value.slice(end);
    editor.setSelectionRange(start, start);
  } else if (start > 0) {
    editor.value = value.slice(0, start - 1) + value.slice(start);
    editor.setSelectionRange(start - 1, start - 1);
  }
  renderCandidates();
  editor.focus();
}

function currentRows(): KeyDef[][] {
  if (layer === "symbols") return SYMBOL_ROWS;
  if (layer === "uly") return ULY_ROWS;
  return LETTER_ROWS.map((row) =>
    row.map((key) => {
      if (key.type !== "char") return key;
      const base = key.insert ?? key.label;
      if (base.length !== 1) return key;
      const label = shift ? base.toUpperCase() : base;
      return { ...key, label, insert: label };
    }),
  );
}

function clearLongPressMenus() {
  keyboardEl.querySelectorAll(".longpress-menu").forEach((el) => el.remove());
}

function showLongPress(btn: HTMLElement, options: string[]) {
  clearLongPressMenus();
  const menu = document.createElement("div");
  menu.className = "longpress-menu";
  for (const opt of options) {
    const b = document.createElement("button");
    b.type = "button";
    b.textContent = opt;
    b.addEventListener("click", (e) => {
      e.stopPropagation();
      insertText(opt);
      clearLongPressMenus();
    });
    menu.appendChild(b);
  }
  btn.appendChild(menu);
}

function handleAction(action: string) {
  switch (action) {
    case "backspace":
      backspace();
      break;
    case "space":
      insertText(" ");
      break;
    case "return":
      insertText("\n");
      break;
    case "shift":
      shift = !shift;
      renderKeyboard();
      break;
    case "symbols":
      layer = "symbols";
      renderKeyboard();
      break;
    case "uly":
      layer = "uly";
      renderKeyboard();
      break;
    case "letters":
      layer = "letters";
      renderKeyboard();
      break;
  }
}

function renderKeyboard() {
  keyboardEl.innerHTML = "";
  for (const row of currentRows()) {
    const rowEl = document.createElement("div");
    rowEl.className = "row";
    for (const key of row) {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "key";
      if (key.type === "action") {
        btn.classList.add("special");
        if (key.wide) btn.classList.add("wide");
        if (key.space) btn.classList.add("space");
        btn.textContent = key.label;
        btn.addEventListener("click", () => handleAction(key.action));
      } else {
        const insert = key.insert ?? key.label;
        btn.textContent = key.label;
        if (key.longPress?.length) {
          const hint = document.createElement("span");
          hint.className = "hint";
          hint.textContent = key.longPress[0]!;
          btn.appendChild(hint);
        }
        let armed = false;
        btn.addEventListener("pointerdown", (e) => {
          e.preventDefault();
          armed = true;
          clearLongPressMenus();
          if (longPressTimer) window.clearTimeout(longPressTimer);
          if (key.longPress?.length) {
            longPressTimer = window.setTimeout(() => {
              longPressTimer = null;
              armed = false;
              showLongPress(btn, key.longPress!);
            }, 380);
          }
        });
        btn.addEventListener("pointerup", () => {
          if (longPressTimer) {
            window.clearTimeout(longPressTimer);
            longPressTimer = null;
          }
          if (armed) {
            armed = false;
            insertText(insert);
          }
        });
        btn.addEventListener("pointercancel", () => {
          armed = false;
          if (longPressTimer) {
            window.clearTimeout(longPressTimer);
            longPressTimer = null;
          }
        });
      }
      rowEl.appendChild(btn);
    }
    keyboardEl.appendChild(rowEl);
  }
}

editor.addEventListener("input", () => renderCandidates());
editor.addEventListener("click", () => renderCandidates());
editor.addEventListener("keyup", () => renderCandidates());

renderKeyboard();

(async () => {
  try {
    const store = await LexiconStore.load("/data/lexicon.json");
    engine = new SuggestionEngine(store);
    setStatus(
      `Offline · ${store.meta.wordCount.toLocaleString()} söz · ${store.meta.script}`,
      "ready",
    );
    renderCandidates();
  } catch (err) {
    console.error(err);
    setStatus("Lexicon yüklenmedi. tools/build_lexicon.py ni ishleting.", "error");
  }
})();
