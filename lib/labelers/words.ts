'use babel';

import * as _ from 'lodash';
import { LabelEnvironment, Label, Labeler } from '../label-interface';
import { addJumpModeClasses } from '../viewHelpers';
import { Point, Range, TextEditor } from 'atom';

function getVisibleColumnRange (editorView: any): Array<number> {
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

// Taken from jQuery: https://github.com/jquery/jquery/blob/master/src/css/hiddenVisibleSelectors.js
function isVisible(element) {
    return !!(element.offsetWidth || element.offsetHeight || element.getClientRects().length);
}

class WordLabel implements Label {
    // TODO: check I need these defined again?
    keyLabel: string | undefined;
    textEditor: TextEditor | null;
    element: HTMLElement | null;
    settings: any;

    // WordLabel specific:
    lineNumber: number;
    column: number;
    marker: any;

    destroy() {
        this.marker.destroy();
    }

    drawLabel(): Label {
        const { textEditor, lineNumber, column, keyLabel } = this;

        this.marker = textEditor.markScreenRange(new Range(
            new Point(lineNumber, column),
            new Point(lineNumber, column)),
            { invalidate: 'touch'});

        const labelElement = document.createElement('div');
        labelElement.textContent = keyLabel;
        labelElement.style.fontSize = this.settings.fontSize;
        labelElement.classList.add('jumpy-label'); // For styling and tests

        if (this.settings.highContrast) {
           labelElement.classList.add('high-contrast');
        }

        const decoration = textEditor.decorateMarker(this.marker,
            {
                type: 'overlay',
                item: labelElement,
                position: 'head'
            });
        this.element = labelElement;
        return this;
    }

    animateBeacon(input: any) {
        const position = input;
        const range = Range(position, position);
        const marker = this.textEditor.markScreenRange(range, { invalidate: 'never' });
        const beacon = document.createElement('span');
        beacon.classList.add('beacon'); // For styling and tests
        this.textEditor.decorateMarker(marker,
            {
                item: beacon,
                type: 'overlay'
            });
        setTimeout(function() {
            marker.destroy();
        } , 150);
    }

    jump() {
        const currentEditor = this.textEditor;
        const editorView = atom.views.getView(currentEditor);

        // TODO: pretty sure this can't be useful...anymore
        // I think it had somethign to do with the observers etc.
        // Prevent other editors from jumping cursors as well
        // TODO: make a test for this if return
        if (currentEditor.id !== this.textEditor.id) {
            return;
        }

        const pane = atom.workspace.paneForItem(currentEditor);
        pane.activate();

        // isVisualMode is for vim-mode or vim-mode-plus:
        const isVisualMode = editorView.classList.contains('visual-mode');
        // isSelected is for regular selection in atom or in insert-mode in vim
        const isSelected = (currentEditor.getSelections().length === 1 &&
            currentEditor.getSelectedText() !== '');
        const position = Point(this.lineNumber, this.column);
        if (isVisualMode || isSelected) {
            currentEditor.selectToScreenPosition(position);
        } else {
            currentEditor.setCursorScreenPosition(position);
        }

        if (atom.config.get('jumpy.useHomingBeaconEffectOnJumps')) {
            this.animateBeacon(position);
        }
    }
}

const labeler: Labeler = function(env:LabelEnvironment):Array<WordLabel> {
    const labels:Array<WordLabel> = [];
    env.settings.wordsPattern.lastIndex = 0; // reset the RegExp for subsequent calls.
    for (const textEditor:AtomCore.IEditor of <Array<AtomCore.IEditor>>atom.workspace.getTextEditors()) {
        const editorView = atom.views.getView(textEditor);

        // 'jumpy-jump-mode is for keymaps and utilized by tests
        addJumpModeClasses(editorView);

        // current labels for current textEditor in loop.
        if (!env.keys.length) {
            continue;
        }

        const [ minColumn, maxColumn ] = getVisibleColumnRange(editorView);
        const rows = textEditor.getVisibleRowRange();

        if (!rows || !isVisible(editorView)) {
            continue;
        }

        const [ firstVisibleRow, lastVisibleRow ] = rows;
        // TODO: Right now there are issues with lastVisbleRow
        for (const lineNumber of _.range(firstVisibleRow, lastVisibleRow) /*excludes end value*/) {
            const lineContents = textEditor.lineTextForScreenRow(lineNumber);
            if (textEditor.isFoldedAtScreenRow(lineNumber)) {
                if (!env.keys.length) {
                    continue; // try continue?
                }

                const keyLabel = env.keys.shift();

                const label = new WordLabel();
                label.settings = env.settings;
                label.textEditor = textEditor;
                label.keyLabel = keyLabel;
                label.lineNumber = lineNumber;
                label.column = 0;
                labels.push(label);
            } else {
                let word: any;
                while ((word = env.settings.wordsPattern.exec(lineContents)) != null && env.keys.length) {
                    const keyLabel = env.keys.shift()

                    const column = word.index;
                    // Do not do anything... markers etc.
                    // if the columns are out of bounds...
                    if (column > minColumn && column < maxColumn) {
                        const label = new WordLabel();
                        label.settings = env.settings;
                        label.textEditor = textEditor;
                        label.keyLabel = keyLabel;
                        label.lineNumber = lineNumber;
                        label.column = column;
                        labels.push(label);
                    }
                }
            }
        } // end: each line
    } // end: for each textEditor

    return labels;
}

export default labeler;
