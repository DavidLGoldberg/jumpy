{Point, Range} = require 'atom'
{$} = require 'space-pen'
LabelManager = require '../label-manager'

class TextEditorLabelManager extends LabelManager
    constructor: (args...) ->
        super args...
        @allPositions = {}
        @decorations = []

    toggle: (keys) ->
        @disposables.add atom.workspace.observeTextEditors (editor) =>
            editorView = atom.views.getView(editor)
            $editorView = $(editorView)
            return if $editorView.is ':not(:visible)'

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

            drawLabels = (lineNumber, column) =>
                return unless keys.length

                keyLabel = keys.shift()
                position = {row: lineNumber, column: column}
                # creates a reference:
                @allPositions[keyLabel] =
                    editor: editor.id
                    position: position

                marker = editor.markScreenRange new Range(
                    new Point(lineNumber, column),
                    new Point(lineNumber, column)),
                    invalidate: 'touch'

                decoration = editor.decorateMarker marker,
                    type: 'overlay'
                    item: @createLabel keyLabel
                    position: 'head'

                @decorations.push decoration

            [minColumn, maxColumn] = getVisibleColumnRange editorView
            rows = editor.getVisibleRowRange()
            return unless rows

            [firstVisibleRow, lastVisibleRow] = rows
            # TODO: Right now there are issues with lastVisbleRow
            for lineNumber in [firstVisibleRow...lastVisibleRow]
                lineContents = editor.lineTextForScreenRow(lineNumber)
                if editor.isFoldedAtScreenRow(lineNumber)
                    drawLabels lineNumber, 0
                else
                    while ((word = @matchPattern.exec(lineContents)) != null)
                        column = word.index
                        # Do not do anything... markers etc.
                        # if the columns are out of bounds...
                        if column > minColumn && column < maxColumn
                            drawLabels lineNumber, column

    jumpTo: (firstChar, secondChar) ->
        location = @findLocation firstChar, secondChar
        if location == null
            return
        @disposables.add atom.workspace.observeTextEditors (currentEditor) =>
            editorView = atom.views.getView(currentEditor)

            # Prevent other editors from jumping cursors as well
            # TODO: make a test for this return if
            return if currentEditor.id != location.editor

            pane = atom.workspace.paneForItem(currentEditor)
            pane.activate()

            isVisualMode = editorView.classList.contains 'visual-mode'
            isSelected = (currentEditor.getSelections().length == 1 &&
                currentEditor.getSelectedText() != '')
            if (isVisualMode || isSelected)
                currentEditor.selectToScreenPosition location.position
            else
                currentEditor.setCursorScreenPosition location.position

            if atom.config.get 'jumpy.useHomingBeaconEffectOnJumps'
                @drawBeacon currentEditor, location

    drawBeacon: (editor, location) ->
        range = Range location.position, location.position
        marker = editor.markScreenRange range, invalidate: 'never'
        beacon = @createBeacon()
        editor.decorateMarker marker,
            item: beacon,
            type: 'overlay'
        setTimeout ->
            marker.destroy()
        , 150

    destroy: ->
        decoration.getMarker().destroy() for decoration in @decorations
        @decorations = [] # Very important for GC.
        # Verifiable in Dev Tools -> Timeline -> Nodes.

    findLocation: (firstChar, secondChar) ->
        label = "#{firstChar}#{secondChar}"
        @allPositions[label] || null

    markIrrelevant: (firstChar) ->
        for decoration in @decorations
            element = decoration.getProperties().item
            if element.textContent.indexOf(firstChar) != 0
                element.classList.add 'irrelevant'

    unmarkIrrelevant: ->
        for decoration in @decorations
            decoration.getProperties().item.classList.remove 'irrelevant'

    findByCharacterAndPosition: (character, position) ->
        for decoration in @decorations
            element = decoration.getProperties().item
            return decoration if element.textContent[position] == character
        null

module.exports = TextEditorLabelManager
