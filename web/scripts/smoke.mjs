import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

// Minimal smoke against generated lexicon without Vite.
const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const bundle = JSON.parse(readFileSync(join(root, "public/data/lexicon.json"), "utf8"));

const words = new Map(bundle.words.map(([w, f]) => [w, f]));
const assert = (cond, msg) => {
  if (!cond) throw new Error(msg);
};

assert(words.has("uyghur"), "missing uyghur");
assert(words.has("bügün"), "missing bügün");
assert(bundle.corrections.bugun === "bügün", "bugun correction");

const prefs = bundle.words
  .filter(([w]) => w.startsWith("uygh"))
  .sort((a, b) => b[1] - a[1])
  .slice(0, 5)
  .map(([w]) => w);
assert(prefs.includes("uyghur"), "prefix uyghur");

console.log("smoke ok", {
  wordCount: bundle.meta.wordCount,
  prefs,
  bugun: bundle.corrections.bugun,
});
