"use strict";
'use babel';
Object.defineProperty(exports, "__esModule", { value: true });
const _ = require("lodash");
const atom_1 = require("atom");
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
function drawLabel(position, settings) {
    const { editor, lineNumber, column, keyLabel } = position;
    const marker = editor.markScreenRange(new atom_1.Range(new atom_1.Point(lineNumber, column), new atom_1.Point(lineNumber, column)), { invalidate: 'touch' });
    const labelElement = document.createElement('div');
    labelElement.textContent = keyLabel;
    labelElement.style.fontSize = settings.fontSize;
    labelElement.classList.add('jumpy-label'); // For styling and tests
    if (settings.highContrast) {
        labelElement.classList.add('high-contrast');
    }
    const decoration = editor.decorateMarker(marker, {
        type: 'overlay',
        item: labelElement,
        position: 'head'
    });
    return decoration;
}
function animateBeacon(editor, position) {
    const range = atom_1.Range(position, position);
    const marker = editor.markScreenRange(range, { invalidate: 'never' });
    const beacon = document.createElement('span');
    beacon.classList.add('beacon'); // For styling and tests
    editor.decorateMarker(marker, {
        item: beacon,
        type: 'overlay'
    });
    setTimeout(function () {
        marker.destroy();
    }, 150);
}
function jumpToWord(location) {
    const currentEditor = location.editor;
    const editorView = atom.views.getView(currentEditor);
    // Prevent other editors from jumping cursors as well
    // TODO: make a test for this if return
    if (currentEditor.id !== location.editor.id) {
        return;
    }
    const pane = atom.workspace.paneForItem(currentEditor);
    pane.activate();
    // isVisualMode is for vim-mode or vim-mode-plus:
    const isVisualMode = editorView.classList.contains('visual-mode');
    // isSelected is for regular selection in atom or in insert-mode in vim
    const isSelected = (currentEditor.getSelections().length === 1 &&
        currentEditor.getSelectedText() !== '');
    const position = atom_1.Point(location.lineNumber, location.column);
    if (isVisualMode || isSelected) {
        currentEditor.selectToScreenPosition(position);
    }
    else {
        currentEditor.setCursorScreenPosition(position);
    }
    if (atom.config.get('jumpy.useHomingBeaconEffectOnJumps')) {
        location.animateBeacon(currentEditor, position);
    }
}
const labeler = function (env) {
    const positions = [];
    const [minColumn, maxColumn] = getVisibleColumnRange(env.editorView);
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
    const [firstVisibleRow, lastVisibleRow] = rows;
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
                jump: jumpToWord,
                lineNumber,
                column: 0,
                keyLabel
            });
        }
        else {
            let word;
            while ((word = env.settings.wordsPattern.exec(lineContents)) != null && env.keys.length) {
                const keyLabel = env.keys.shift();
                const column = word.index;
                // Do not do anything... markers etc.
                // if the columns are out of bounds...
                if (column > minColumn && column < maxColumn) {
                    positions.push({
                        editor: env.editor,
                        drawLabel: drawLabel,
                        animateBeacon: animateBeacon,
                        jump: jumpToWord,
                        lineNumber,
                        column,
                        keyLabel
                    });
                }
            }
        }
    }
    return positions;
};
exports.default = labeler;
//# sourceMappingURL=words.js.map