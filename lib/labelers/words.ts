'use babel';

import * as _ from 'lodash';
import { LabelEnvironment, Label, Labeler } from '../label-interface';
import { Point, Range } from 'atom';

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

function drawLabel(position: any, settings: any) {
    const { editor, lineNumber, column, keyLabel } = position;

    const marker = editor.markScreenRange(new Range(
        new Point(lineNumber, column),
        new Point(lineNumber, column)),
        { invalidate: 'touch'});

    const labelElement = document.createElement('div');
    labelElement.textContent = keyLabel;
    labelElement.style.fontSize = settings.fontSize;
    labelElement.classList.add('jumpy-label'); // For styling and tests

    if (settings.highContrast) {
       labelElement.classList.add('high-contrast');
    }

    const decoration = editor.decorateMarker(marker,
        {
            type: 'overlay',
            item: labelElement,
            position: 'head'
        });
    return decoration;
}

function animateBeacon(editor: any, position: any) {
    const range = Range(position, position);
    const marker = editor.markScreenRange(range, { invalidate: 'never' });
    const beacon = document.createElement('span');
    beacon.classList.add('beacon'); // For styling and tests
    editor.decorateMarker(marker,
        {
            item: beacon,
            type: 'overlay'
        });
    setTimeout(function() {
        marker.destroy();
    } , 150);
}

// type MergedLabelInterface = Label;
// augment existing Label (defined above) to allow for words so...lineNumber, columns, keys
// typescript feature is called: "merging interfaces" mixin ish.
interface Label {
    lineNumber: number;
    column: number;
    keyLabel: string;
}

const labeler: Labeler = function(env:LabelEnvironment):Array<any> {
    const positions = [];

    const [ minColumn, maxColumn ] = getVisibleColumnRange(env.editorView);
    const rows = env.editor.getVisibleRowRange();

    if (!rows) {
        return [];
    }

    // TODO: This would be nicer...set up an initial shared portion
    // let label: Label = {
    //     editor: env.editor,
    //     drawLabel: drawLabel,
    //     animateBeacon: animateBeacon
    // };

    const [ firstVisibleRow, lastVisibleRow ] = rows;
    // TODO: Right now there are issues with lastVisbleRow
    for (const lineNumber of _.range(firstVisibleRow, lastVisibleRow) /*excludes end value*/) {
        // TODO: This would be nicer...grow it with lineNumber
        // label = { ...label, lineNumber };
        const lineContents = env.editor.lineTextForScreenRow(lineNumber);
        if (env.editor.isFoldedAtScreenRow(lineNumber)) {
            if (!env.keys.length) {
                return; // try continue?
            }

            const keyLabel = env.keys.shift();

            positions.push({
                editor: env.editor,
                drawLabel: drawLabel,
                animateBeacon: animateBeacon,
                lineNumber,
                column: 0,
                keyLabel
            });
        } else {
            let word: any;
            while ((word = env.settings.wordsPattern.exec(lineContents)) != null && env.keys.length) {
                const keyLabel = env.keys.shift()

                const column = word.index;
                // Do not do anything... markers etc.
                // if the columns are out of bounds...
                if (column > minColumn && column < maxColumn) {
                    positions.push({
                        editor: env.editor,
                        drawLabel: drawLabel,
                        animateBeacon: animateBeacon,
                        lineNumber,
                        column,
                        keyLabel
                    });
                }
            }
        }
    }

    return positions;
}

export default labeler;
