getVisibleColumnRange = (editorView) ->
    charWidth = editorView.getDefaultCharacterWidth()
    # FYI: asserts:
    # numberOfVisibleColumns = editorView.getWidth() / charWidth
    minColumn = (editorView.getScrollLeft() / charWidth) - 1
    maxColumn = editorView.getScrollRight() / charWidth

    return [
        minColumn
        maxColumn
    ]

getLabels = (editor, editorView, keys, settings) ->
    positions = []
    [minColumn, maxColumn] = getVisibleColumnRange editorView
    rows = editor.getVisibleRowRange()

    if !rows
        return

    [firstVisibleRow, lastVisibleRow] = rows
    # TODO: Right now there are issues with lastVisbleRow
    for lineNumber in [firstVisibleRow...lastVisibleRow]
        lineContents = editor.lineTextForScreenRow(lineNumber)
        if editor.isFoldedAtScreenRow(lineNumber)
            return unless keys.length
            keyLabel = keys.shift()

            positions.push { editor, lineNumber, column: 0, keyLabel }
        else
            while ((word = settings.wordsPattern.exec(lineContents)) != null && keys.length)
                keyLabel = keys.shift()

                column = word.index
                # Do not do anything... markers etc.
                # if the columns are out of bounds...
                if column > minColumn && column < maxColumn
                    positions.push { editor, lineNumber, column, keyLabel }

    return positions

module.exports = { getLabels }
