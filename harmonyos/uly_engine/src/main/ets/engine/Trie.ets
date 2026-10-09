import { lookupKey } from './Uly';

class TrieNode {
  children: Map<string, TrieNode> = new Map();
  isWord: boolean = false;
  frequency: number = 0;
  word: string = '';
  bestFrequency: number = 0;
}

export class PrefixTrie {
  private root: TrieNode = new TrieNode();

  insert(word: string, frequency: number): void {
    const key = lookupKey(word);
    let node = this.root;
    const path: TrieNode[] = [node];
    for (let i = 0; i < key.length; i++) {
      const ch = key.charAt(i);
      let next = node.children.get(ch);
      if (!next) {
        next = new TrieNode();
        node.children.set(ch, next);
      }
      node = next;
      path.push(node);
    }
    node.isWord = true;
    node.frequency = Math.max(node.frequency, frequency);
    node.word = key;
    for (let i = 0; i < path.length; i++) {
      path[i].bestFrequency = Math.max(path[i].bestFrequency, node.frequency);
    }
  }

  contains(word: string): boolean {
    const node = this.walk(lookupKey(word));
    return !!node && node.isWord;
  }

  frequency(word: string): number {
    const node = this.walk(lookupKey(word));
    return node && node.isWord ? node.frequency : 0;
  }

  /**
   * Bounded best-first completions — keeps IME candidate refresh cheap.
   */
  completions(prefix: string, limit: number = 8): Array<[string, number]> {
    if (limit <= 0) {
      return [];
    }
    const key = lookupKey(prefix);
    if (!key) {
      return [];
    }
    const start = this.walk(key);
    if (!start) {
      return [];
    }

    const heap: Array<[string, number]> = [];
    const consider = (w: string, f: number): void => {
      if (heap.length < limit) {
        heap.push([w, f]);
        heap.sort((a, b) => a[1] - b[1]);
        return;
      }
      if (f > heap[0][1]) {
        heap[0] = [w, f];
        heap.sort((a, b) => a[1] - b[1]);
      }
    };

    const stack: TrieNode[] = [start];
    let visited = 0;
    const visitCap = Math.max(limit * 64, 256);
    while (stack.length > 0 && visited < visitCap) {
      const node = stack.pop() as TrieNode;
      visited++;
      if (node.isWord && node.word) {
        consider(node.word, node.frequency);
      }
      const kids = Array.from(node.children.values()).sort((a, b) => a.bestFrequency - b.bestFrequency);
      for (let i = 0; i < kids.length; i++) {
        const child = kids[i];
        if (heap.length >= limit && child.bestFrequency <= heap[0][1]) {
          continue;
        }
        stack.push(child);
      }
    }

    return heap.sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0));
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
}
