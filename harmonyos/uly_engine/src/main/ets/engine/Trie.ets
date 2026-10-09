import { lookupKey } from './Uly';

class TrieNode {
  children: Map<string, TrieNode> = new Map();
  isWord: boolean = false;
  frequency: number = 0;
  word: string = '';
}

export class PrefixTrie {
  private root: TrieNode = new TrieNode();

  insert(word: string, frequency: number): void {
    const key = lookupKey(word);
    let node = this.root;
    for (let i = 0; i < key.length; i++) {
      const ch = key.charAt(i);
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
    return !!node && node.isWord;
  }

  frequency(word: string): number {
    const node = this.walk(lookupKey(word));
    return node && node.isWord ? node.frequency : 0;
  }

  completions(prefix: string, limit: number = 8): Array<[string, number]> {
    const key = lookupKey(prefix);
    if (!key) {
      return [];
    }
    const node = this.walk(key);
    if (!node) {
      return [];
    }
    const results: Array<[string, number]> = [];
    this.collect(node, results, Math.max(limit * 4, 32));
    results.sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0));
    return results.slice(0, limit);
  }

  private walk(key: string): TrieNode | null {
    let node = this.root;
    for (let i = 0; i < key.length; i++) {
      const next = node.children.get(key.charAt(i));
      if (!next) {
        return null;
      }
      node = next;
    }
    return node;
  }

  private collect(node: TrieNode, results: Array<[string, number]>, limit: number): void {
    if (results.length >= limit) {
      return;
    }
    if (node.isWord && node.word) {
      results.push([node.word, node.frequency]);
    }
    const keys = Array.from(node.children.keys()).sort();
    for (let i = 0; i < keys.length; i++) {
      const child = node.children.get(keys[i]);
      if (child) {
        this.collect(child, results, limit);
      }
      if (results.length >= limit) {
        return;
      }
    }
  }
}
