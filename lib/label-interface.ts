import { TextEditor } from 'atom';

export interface LabelEnvironment {
    keys: Array<string>;
    settings: any;
}

export interface Label {
    // TODO: can I make this | null instead of undefined?
    keyLabel: string | undefined;
    textEditor: TextEditor | null;
    element: HTMLElement | null;
    settings: any;
    drawLabel(): Label;
    animateBeacon(input: any): void;
    jump(): void;
    destroy(): void;
}

export interface Labeler {
    (environment:LabelEnvironment):Array<Label>;
}
