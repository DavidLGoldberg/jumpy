"use strict";
'use babel';
Object.defineProperty(exports, "__esModule", { value: true });
const _ = require("lodash");
function getKeySet(customKeys) {
    let lowerCharacters = [];
    let upperCharacters = [];
    if (!customKeys.length) {
        lowerCharacters = _.range('a'.charCodeAt(0), 'z'.charCodeAt(0) + 1 /* for inclusive*/)
            .map(c => String.fromCharCode(c));
        upperCharacters = _.range('A'.charCodeAt(0), 'Z'.charCodeAt(0) + 1 /* for inclusive*/)
            .map(c => String.fromCharCode(c));
    }
    else {
        for (let key of customKeys) {
            lowerCharacters.push(key.toLowerCase());
            upperCharacters.push(key.toUpperCase());
        }
    }
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
    // TODO: use TS's ReadonlyArray?
    return keys;
}
exports.getKeySet = getKeySet;
//# sourceMappingURL=keys.js.map