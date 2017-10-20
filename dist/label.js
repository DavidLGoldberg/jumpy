"use strict";
'use babel';
Object.defineProperty(exports, "__esModule", { value: true });
const atom_1 = require("atom");
const _ = require("lodash");
const lowerCharacters = _.range('a'.charCodeAt(0), 'z'.charCodeAt(0) + 1 /* for inclusive*/)
    .map(c => String.fromCharCode(c));
const upperCharacters = _.range('A'.charCodeAt(0), 'Z'.charCodeAt(0) + 1 /* for inclusive*/)
    .map(c => String.fromCharCode(c));
const keys = [];
// A little ugly.
// I used itertools.permutation in python.
// Couldn't find a good one in npm.  Don't worry this takes < 1ms once.
// TODO: try a zip? and or make a func
for (let c1 of lowerCharacters) {
    for (let c2 of lowerCharacters) {
        keys.push(c1 + c2);
    }
}
for (let c1 of upperCharacters) {
    for (let c2 of lowerCharacters) {
        keys.push(c1 + c2);
    }
}
for (let c1 of lowerCharacters) {
    for (let c2 of upperCharacters) {
        keys.push(c1 + c2);
    }
}
function getKeySet() {
    return _.clone(keys);
}
exports.getKeySet = getKeySet;
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
exports.drawLabel = drawLabel;
function drawBeacon(editor, position) {
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
exports.drawBeacon = drawBeacon;
//# sourceMappingURL=label.js.map