'use babel';

import { Label } from './label-interface';

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

export default function labelReducer (labels: Array<Label>, currentKey : string) {
    return labels.filter(function(label : Label) {
        if (!label.keyLabel) {
            return false;
        }
        return label.keyLabel.startsWith(currentKey);
    });
}
