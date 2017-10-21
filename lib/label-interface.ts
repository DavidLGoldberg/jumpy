export interface LabelEnvironment {
    editor: any,
    editorView: any,
    keys: Array<string>,
    settings: any
}

export interface Label {
    editor: any;
    drawLabel: any;
    animateBeacon: any;
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
