'use babel';

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
