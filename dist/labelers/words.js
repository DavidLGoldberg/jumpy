"use strict";
'use babel';
Object.defineProperty(exports, "__esModule", { value: true });
const _ = require("lodash");
function getVisibleColumnRange(editorView) {
    const charWidth = editorView.getDefaultCharacterWidth();
    // FYI: asserts:
    // numberOfVisibleColumns = editorView.getWidth() / charWidth
    const minColumn = (editorView.getScrollLeft() / charWidth) - 1;
    const maxColumn = editorView.getScrollRight() / charWidth;
    return [
        minColumn,
        maxColumn
    ];
}
function getLabels(editor, editorView, keys, settings) {
    const positions = [];
    const [minColumn, maxColumn] = getVisibleColumnRange(editorView);
    const rows = editor.getVisibleRowRange();
    if (!rows) {
        return;
    }
    const [firstVisibleRow, lastVisibleRow] = rows;
    // TODO: Right now there are issues with lastVisbleRow
    for (const lineNumber of _.range(firstVisibleRow, lastVisibleRow) /*excludes end value*/) {
        const lineContents = editor.lineTextForScreenRow(lineNumber);
        if (editor.isFoldedAtScreenRow(lineNumber)) {
            if (!keys.length) {
                return;
            }
            const keyLabel = keys.shift();
            positions.push({ editor, lineNumber, column: 0, keyLabel });
        }
        else {
            let word;
            while ((word = settings.wordsPattern.exec(lineContents)) != null && keys.length) {
                const keyLabel = keys.shift();
                const column = word.index;
                // Do not do anything... markers etc.
                // if the columns are out of bounds...
                if (column > minColumn && column < maxColumn) {
                    positions.push({ editor, lineNumber, column, keyLabel });
                }
            }
        }
    }
    return positions;
}
exports.default = getLabels;
//# sourceMappingURL=words.js.map