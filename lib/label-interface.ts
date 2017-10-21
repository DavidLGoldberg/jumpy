export interface LabelEnvironment {
    editor: any,
    editorView: any,
    keys: Array<string>,
    settings: any
}

export interface Label {
    // TODO: keyLabel should probably be put here as opposed to the instances
    editor: any;
    drawLabel(label: Label): void;
    animateBeacon(label: Label): void;
    jump(label: Label): void;
}

export interface Labeler {
    (environment:LabelEnvironment):Array<any>;
}

// need these?
export interface Drawable {
    (label:Label):any;
}
export interface Beaconable {
    (label:Label):any;
}
