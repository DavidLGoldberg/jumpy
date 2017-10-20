'use babel';

import { Point, Range } from 'atom';
import * as _ from 'lodash';

const lowerCharacters: Array<string> = _.range('a'.charCodeAt(0), 'z'.charCodeAt(0) + 1 /* for inclusive*/)
    .map(c => String.fromCharCode(c));
const upperCharacters: Array<string> = _.range('A'.charCodeAt(0), 'Z'.charCodeAt(0) + 1 /* for inclusive*/)
    .map(c => String.fromCharCode(c));

const keys: Array<string> = [];

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

export function getKeySet() {
    return _.clone(keys);
}

export function drawLabel(position: any, settings: any) {
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

export function drawBeacon(editor: any, position: any) {
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
