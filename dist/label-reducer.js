"use strict";
'use babel';
Object.defineProperty(exports, "__esModule", { value: true });
// (PURE FUNCTION)
//
// WHEN GIVEN:
//
//      1.  AN ARRAY OF LABELS (* SEE BELOW)
//      (and)
//      2. A NEW INPUT KEY
//
// RETURNS new collection of labels
// *without* the labels that do not start with the current key
function labelReducer(labels, currentKey) {
    return labels.filter(function (label) {
        if (!label.keyLabel) {
            return false;
        }
        return label.keyLabel.startsWith(currentKey);
    });
}
exports.default = labelReducer;
//# sourceMappingURL=label-reducer.js.map