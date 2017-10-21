'use babel';

import * as _ from 'lodash';
import { LabelEnvironment } from '../label-interface';

function getVisibleColumnRange (editorView: any) {
    const charWidth = editorView.getDefaultCharacterWidth()
    // FYI: asserts:
    // numberOfVisibleColumns = editorView.getWidth() / charWidth
    const minColumn = (editorView.getScrollLeft() / charWidth) - 1
    const maxColumn = editorView.getScrollRight() / charWidth

    return [
        minColumn,
        maxColumn
    ];
}

export default function getLabels (env:LabelEnvironment) {
    const positions = [];

    const [ minColumn, maxColumn ] = getVisibleColumnRange(env.editorView);
    const rows = env.editor.getVisibleRowRange();

    if (!rows) {
        return;
    }

    const [ firstVisibleRow, lastVisibleRow ] = rows;
    // TODO: Right now there are issues with lastVisbleRow
    for (const lineNumber of _.range(firstVisibleRow, lastVisibleRow) /*excludes end value*/) {
        const lineContents = env.editor.lineTextForScreenRow(lineNumber);
        if (env.editor.isFoldedAtScreenRow(lineNumber)) {
            if (!env.keys.length) {
                return;
            }

            const keyLabel = env.keys.shift();

            positions.push({ editor: env.editor, lineNumber, column: 0, keyLabel });
        } else {
            let word: any;
            while ((word = env.settings.wordsPattern.exec(lineContents)) != null && env.keys.length) {
                const keyLabel = env.keys.shift()

                const column = word.index;
                // Do not do anything... markers etc.
                // if the columns are out of bounds...
                if (column > minColumn && column < maxColumn) {
                    positions.push({ editor: env.editor, lineNumber, column, keyLabel });
                }
            }
        }
    }

    return positions;
}
