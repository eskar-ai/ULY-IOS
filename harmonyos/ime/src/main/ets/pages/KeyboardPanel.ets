@Component
export struct KeyboardPanel {
  @Prop candidates: string[] = [];
  @Prop misspelled: boolean = false;
  onKey?: (text: string) => void;
  onDelete?: () => void;
  onSpace?: () => void;
  onReturn?: () => void;
  onCandidate?: (word: string) => void;

  private rows: string[][] = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['⇧', 'z', 'x', 'c', 'v', 'b', 'n', 'm', '⌫'],
    ['ëöü', ',', 'space', '.', '⏎'],
  ];
  @State shiftOn: boolean = false;
  @State specialOn: boolean = false;

  build() {
    Column() {
      Row() {
        ForEach(this.candidates.slice(0, 8), (word: string, index: number) => {
          Text(word)
            .fontSize(16)
            .fontColor(this.misspelled && index === 0 ? '#FF3B30' : '#1C1C1E')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .onClick(() => {
              if (this.onCandidate) {
                this.onCandidate(word);
              }
            })
        }, (word: string) => word)
      }
      .width('100%')
      .height(40)

      ForEach(this.currentRows(), (row: string[], rowIndex: number) => {
        Row() {
          ForEach(row, (label: string) => {
            Button(this.displayLabel(label))
              .layoutWeight(label === 'space' ? 4 : (label === '⇧' || label === '⌫' || label === '⏎' ||
                label === 'ëöü' || label === 'ABC' ? 1.4 : 1))
              .height(48)
              .margin({ left: 2, right: 2 })
              .fontSize(label.length > 2 ? 12 : 18)
              .backgroundColor(this.isSpecialKey(label) ? '#AEB3BE' : '#FFFFFF')
              .fontColor('#1C1C1E')
              .onClick(() => this.handleKey(label))
          }, (label: string) => `${rowIndex}-${label}`)
        }
        .width('100%')
        .margin({ top: 6 })
      }, (_: string[], idx: number) => `row-${idx}`)
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 6, bottom: 8 })
    .backgroundColor('#D1D3D9')
  }

  private currentRows(): string[][] {
    if (this.specialOn) {
      return [
        ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
        ['ë', 'ö', 'ü', 'ch', 'sh', 'zh', 'gh', 'ng', "'"],
        ['ABC', '-', '_', '!', '?', '@', '#', '⌫'],
        ['ëöü', ',', 'space', '.', '⏎'],
      ];
    }
    return this.rows;
  }

  private isSpecialKey(label: string): boolean {
    return ['⇧', '⌫', '⏎', 'ëöü', 'ABC', 'space', ',', '.'].indexOf(label) >= 0;
  }

  private displayLabel(label: string): string {
    if (label === 'space') {
      return 'space';
    }
    if (label === '⏎') {
      return 'return';
    }
    if (label === '⇧') {
      return this.shiftOn ? '⇪' : '⇧';
    }
    if (!this.specialOn && this.shiftOn && label.length === 1) {
      return label.toUpperCase();
    }
    return label;
  }

  private handleKey(label: string): void {
    if (label === '⇧') {
      this.shiftOn = !this.shiftOn;
      return;
    }
    if (label === 'ëöü') {
      this.specialOn = !this.specialOn;
      return;
    }
    if (label === 'ABC') {
      this.specialOn = false;
      return;
    }
    if (label === '⌫') {
      if (this.onDelete) {
        this.onDelete();
      }
      return;
    }
    if (label === 'space') {
      if (this.onSpace) {
        this.onSpace();
      }
      return;
    }
    if (label === '⏎') {
      if (this.onReturn) {
        this.onReturn();
      }
      return;
    }
    let out = label;
    if (!this.specialOn && this.shiftOn && label.length === 1) {
      out = label.toUpperCase();
      this.shiftOn = false;
    }
    if (this.onKey) {
      this.onKey(out);
    }
  }
}
