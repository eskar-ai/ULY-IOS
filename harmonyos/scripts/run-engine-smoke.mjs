#!/usr/bin/env node
/**
 * CI-friendly smoke test without DevEco:
 * validates lexicon.json shape and runs a tiny pure-JS mirror of lookup/trie.
 */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const lexiconPath = join(root, 'ime/src/main/resources/rawfile/lexicon.json');

function lookupKey(text) {
  return text
    .replaceAll('É', 'Ë')
    .replaceAll('é', 'ë')
    .replaceAll('ʼ', "'")
    .replaceAll('\u2019', "'")
    .toLowerCase();
}

function assert(cond, msg) {
  if (!cond) throw new Error(msg);
}

const raw = readFileSync(lexiconPath, 'utf8');
const bundle = JSON.parse(raw);
assert(bundle.meta?.script, 'meta.script missing');
assert(Array.isArray(bundle.words) && bundle.words.length > 1000, 'words too small');
assert(bundle.corrections && typeof bundle.corrections === 'object', 'corrections missing');
assert(Array.isArray(bundle.bigrams), 'bigrams missing');

assert(lookupKey('ÉlÉm') === 'ëlëm', 'lookupKey fold failed');

const prefixes = ['uygh', 'bügün', 'aq'];
const found = {};
for (const [w, f] of bundle.words) {
  const key = lookupKey(w);
  for (const p of prefixes) {
    if (!found[p] && key.startsWith(p)) {
      found[p] = { word: key, frequency: f };
    }
  }
  if (Object.keys(found).length === prefixes.length) break;
}
for (const p of prefixes) {
  assert(found[p], `expected word starting with "${p}"`);
}

console.log(
  JSON.stringify(
    {
      ok: true,
      version: bundle.meta.version,
      wordCount: bundle.meta.wordCount ?? bundle.words.length,
      found,
    },
    null,
    2,
  ),
);
