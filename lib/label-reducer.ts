'use babel';

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

// A *LABEL* looks like:
// { editor, lineNumber, column, keyLabel }
export default function labelReducer (labels: Array<any>, currentKey : string) {
    return labels.filter(function(label : any) {
        return label.keyLabel.startsWith(currentKey);
    });
}
