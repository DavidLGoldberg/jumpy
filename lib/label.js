'use babel';

import { Point, Range } from 'atom';
import _ from 'lodash';

lowerCharacters = _.range('a'.charCodeAt(), 'z'.charCodeAt() + 1 /* for inclusive*/)
    .map(c => String.fromCharCode(c));
upperCharacters = _.range('A'.charCodeAt(), 'Z'.charCodeAt() + 1 /* for inclusive*/)
    .map(c => String.fromCharCode(c));

keys = [];

// A little ugly.
// I used itertools.permutation in python.
// Couldn't find a good one in npm.  Don't worry this takes < 1ms once.
for (c1 of lowerCharacters) {
    for (c2 of lowerCharacters) {
        keys.push(c1 + c2);
    }
}
for (c1 of upperCharacters) {
    for (c2 of lowerCharacters) {
        keys.push(c1 + c2);
    }
}
for (c1 of lowerCharacters) {
    for (c2 of upperCharacters) {
        keys.push(c1 + c2);
    }
}
getKeySet = function() {
    return _.clone(keys);
}

drawLabel = function (position, settings) {
    const { editor, lineNumber, column, keyLabel } = position;

    const marker = editor.markScreenRange(new Range(
        new Point(lineNumber, column),
        new Point(lineNumber, column)),
        { invalidate: 'touch'});

    labelElement = document.createElement('div');
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
};

drawBeacon = function (editor, position) {
    range = Range(position, position);
    marker = editor.markScreenRange(range, { invalidate: 'never' });
    beacon = document.createElement('span');
    beacon.classList.add('beacon'); // For styling and tests
    editor.decorateMarker(marker,
        {
            item: beacon,
            type: 'overlay'
        });
    setTimeout(function() {
        marker.destroy();
    } , 150);
};

module.exports = { getKeySet, drawLabel, drawBeacon };
