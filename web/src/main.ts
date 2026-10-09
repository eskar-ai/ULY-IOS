import "./style.css";
import { LexiconStore, SuggestionEngine, isWordChar, lookupKey } from "./engine";

const editor = document.querySelector<HTMLTextAreaElement>("#editor")!;
const statusEl = document.querySelector<HTMLElement>("#status")!;
const candidatesEl = document.querySelector<HTMLElement>("#candidates")!;
const keyboardEl = document.querySelector<HTMLElement>("#keyboard")!;
const themeBtn = document.querySelector<HTMLButtonElement>("#themeCycle")!;

type ThemePref = "system" | "light" | "dark";
type KeyDef =
  | { type: "char"; label: string; insert?: string; longPress?: string[]; flex?: number }
  | { type: "action"; action: string; label: string; wide?: boolean; space?: boolean; flex?: number };

const THEME_KEY = "uyghurlatin.themePreference";

const LETTER_ROWS: KeyDef[][] = [
  "qwertyuiop".split("").map((c) => {
    const long =
      c === "e" ? ["ë", "Ë"] : c === "u" ? ["ü", "Ü"] : c === "o" ? ["ö", "Ö"] : undefined;
    return { type: "char" as const, label: c, longPress: long };
  }),
  [
    { type: "char", label: "a" },
    { type: "char", label: "s", longPress: ["sh"] },
    { type: "char", label: "d" },
    { type: "char", label: "f" },
    { type: "char", label: "g", longPress: ["gh"] },
    { type: "char", label: "h" },
    { type: "char", label: "j" },
    { type: "char", label: "k" },
    { type: "char", label: "l" },
  ],
  [
    { type: "action", action: "shift", label: "⇧", wide: true },
    { type: "char", label: "z", longPress: ["zh"] },
    { type: "char", label: "x" },
    { type: "char", label: "c", longPress: ["ch"] },
    { type: "char", label: "v" },
    { type: "char", label: "b" },
    { type: "char", label: "n", longPress: ["ng"] },
    { type: "char", label: "m" },
    { type: "action", action: "backspace", label: "⌫", wide: true },
  ],
  [
    { type: "action", action: "symbols", label: "123", wide: true },
    { type: "action", action: "uly", label: "ëöü", wide: true },
    { type: "action", action: "space", label: "space", space: true },
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
    { type: "action", action: "space", label: "space", space: true },
    { type: "action", action: "return", label: "return", wide: true },
  ],
];

const ULY_ROWS: KeyDef[][] = [
  ["ë", "ö", "ü", "Ë", "Ö", "Ü", "ch", "sh", "zh", "gh"].map((c) => ({
    type: "char" as const,
    label: c,
  })),
  [
    { type: "char", label: "ng" },
    { type: "char", label: "'" },
    { type: "char", label: "-" },
    { type: "char", label: "," },
    { type: "char", label: "." },
    { type: "action", action: "backspace", label: "⌫", wide: true },
  ],
  [
    { type: "action", action: "letters", label: "ABC", wide: true },
    { type: "action", action: "space", label: "space", space: true },
    { type: "action", action: "return", label: "return", wide: true },
  ],
];

let engine: SuggestionEngine | null = null;
let shift = false;
let layer: "letters" | "symbols" | "uly" = "letters";
let longPressTimer: number | null = null;
let themePref: ThemePref = (localStorage.getItem(THEME_KEY) as ThemePref) || "system";

function resolvedTheme(): "light" | "dark" {
  if (themePref === "light" || themePref === "dark") return themePref;
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

function applyTheme() {
  const resolved = resolvedTheme();
  document.documentElement.dataset.theme = resolved;
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute("content", resolved === "dark" ? "#2c2c2e" : "#d1d3d9");
  themeBtn.textContent = `Theme: ${themePref[0]!.toUpperCase()}${themePref.slice(1)}`;
}

function cycleTheme() {
  themePref = themePref === "system" ? "light" : themePref === "light" ? "dark" : "system";
  localStorage.setItem(THEME_KEY, themePref);
  applyTheme();
}

function setStatus(text: string, kind: "error" | "" = "") {
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

function clearLongPressMenus() {
  keyboardEl.querySelectorAll(".longpress-menu").forEach((el) => el.remove());
}

function renderCandidates() {
  candidatesEl.innerHTML = "";
  if (!engine) return;
  const { partial, previous } = getContext();
  const result = engine.suggest(partial, previous, 3);
  const words = result.candidates.slice(0, 3);

  const slots = [0, 1, 2];
  slots.forEach((idx) => {
    if (idx > 0) {
      const sep = document.createElement("div");
      sep.className = "cand-sep";
      candidatesEl.appendChild(sep);
    }
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = `candidate${result.isMisspelled && idx === 0 ? " misspelled" : ""}`;
    btn.textContent = words[idx] ?? "";
    if (words[idx]) {
      btn.addEventListener("click", () => applyCandidate(words[idx]!, partial));
    } else {
      btn.disabled = true;
    }
    candidatesEl.appendChild(btn);
  });

  const theme = document.createElement("button");
  theme.type = "button";
  theme.className = "theme-btn";
  theme.title = "Cycle theme";
  theme.textContent = themePref === "system" ? "◐" : themePref === "light" ? "☀︎" : "☾";
  theme.addEventListener("click", cycleTheme);
  candidatesEl.appendChild(theme);

  if (result.mode === "correction" && words.length) {
    setStatus(`Spelling: ${partial} → ${words.join(", ")}`);
  } else if (engine.meta) {
    setStatus(`Offline · ${engine.meta.wordCount.toLocaleString()} words · ${engine.meta.script}`);
  }
}

function applyCandidate(word: string, partial: string) {
  const value = editor.value;
  const caret = editor.selectionStart ?? value.length;
  const start = caret - partial.length;
  const before = value.slice(0, start);
  const after = value.slice(caret);
  const insert = word + " ";
  editor.value = before + insert + after;
  const pos = (before + insert).length;
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
  if (shift && text.length === 1 && /[a-zëöü]/i.test(text)) {
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
  currentRows().forEach((row, rowIdx) => {
    const rowEl = document.createElement("div");
    rowEl.className = "row" + (layer === "letters" && rowIdx === 1 ? " indent" : "");
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
  });
}

themeBtn.addEventListener("click", cycleTheme);
window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
  if (themePref === "system") applyTheme();
});

editor.addEventListener("input", () => renderCandidates());
editor.addEventListener("click", () => renderCandidates());
editor.addEventListener("keyup", () => renderCandidates());

applyTheme();
renderKeyboard();

(async () => {
  try {
    const store = await LexiconStore.load("/data/lexicon.json");
    engine = new SuggestionEngine(store);
    setStatus(`Offline · ${store.meta.wordCount.toLocaleString()} words · ${store.meta.script}`);
    renderCandidates();
  } catch (err) {
    console.error(err);
    setStatus("Lexicon failed to load. Run tools/build_lexicon.py.", "error");
  }
})();
