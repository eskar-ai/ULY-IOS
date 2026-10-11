import { lookupKey } from "./uly";

class TrieNode {
  children = new Map<string, TrieNode>();
  isWord = false;
  frequency = 0;
  word?: string;
}

export class PrefixTrie {
  private root = new TrieNode();

  insert(word: string, frequency: number): void {
    const key = lookupKey(word);
    let node = this.root;
    for (const ch of key) {
      let next = node.children.get(ch);
      if (!next) {
        next = new TrieNode();
        node.children.set(ch, next);
      }
      node = next;
    }
    node.isWord = true;
    node.frequency = Math.max(node.frequency, frequency);
    node.word = key;
  }

  contains(word: string): boolean {
    const node = this.walk(lookupKey(word));
    return !!node?.isWord;
  }

  frequency(word: string): number {
    const node = this.walk(lookupKey(word));
    return node?.isWord ? node.frequency : 0;
  }

  completions(prefix: string, limit = 8): Array<[string, number]> {
    const key = lookupKey(prefix);
    if (!key) return [];
    const node = this.walk(key);
    if (!node) return [];
    const results: Array<[string, number]> = [];
    this.collect(node, results, Math.max(limit * 4, 32));
    results.sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
    return results.slice(0, limit);
  }

  private walk(key: string): TrieNode | null {
    let node = this.root;
    for (const ch of key) {
      const next = node.children.get(ch);
      if (!next) return null;
      node = next;
    }
    return node;
  }

  private collect(node: TrieNode, results: Array<[string, number]>, limit: number): void {
    if (results.length >= limit) return;
    if (node.isWord && node.word) results.push([node.word, node.frequency]);
    const keys = [...node.children.keys()].sort();
    for (const k of keys) {
      this.collect(node.children.get(k)!, results, limit);
      if (results.length >= limit) return;
    }
  }
}
