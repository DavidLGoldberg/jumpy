export interface LabelEnvironment {
    editor: any,
    editorView: any,
    keys: Array<string>,
    settings: any
}

export interface Labeler {
    getLabels(environment:LabelEnvironment):Array<any>;
}
