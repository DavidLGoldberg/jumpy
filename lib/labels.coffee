{CompositeDisposable, Point, Range} = require 'atom'
{$} = require 'space-pen'
_ = require 'lodash'

lowerCharacters =
    (String.fromCharCode(a) for a in ['a'.charCodeAt()..'z'.charCodeAt()])
upperCharacters =
    (String.fromCharCode(a) for a in ['A'.charCodeAt()..'Z'.charCodeAt()])
keys = []

# A little ugly.
# I used itertools.permutation in python.
# Couldn't find a good one in npm.  Don't worry this takes < 1ms once.
for c1 in lowerCharacters
    for c2 in lowerCharacters
        keys.push c1 + c2
for c1 in upperCharacters
    for c2 in lowerCharacters
        keys.push c1 + c2
for c1 in lowerCharacters
    for c2 in upperCharacters
        keys.push c1 + c2

class Labels
    constructor: (@disposables = new CompositeDisposable()) ->
        @allPositions = {}
        @decorations = []
        atom.config.observe 'jumpy.fontSize', @setFontSize
        atom.config.observe 'jumpy.matchPattern', @setWordsPattern
        atom.config.observe 'jumpy.highContrast', @setHighContrast

    setHighContrast: (value) =>
        @highContrast = value

    setWordsPattern: (value) =>
        @matchPattern = new RegExp value, 'g'

    setFontSize: (value) =>
        value = .75 if isNaN(value) or value > 1
        @fontSize = (value * 100) + '%'

    createLabel: (text) ->
        labelElement = document.createElement('span')
        labelElement.textContent = text
        labelElement.style.fontSize = @fontSize
        labelElement.classList.add 'jumpy-label'
        labelElement.classList.add 'high-contrast' if @highContrast
        labelElement

    toggleTreeView: (keys) ->
        elements = document.querySelectorAll(
            '.tree-view li.file, .tree-view li.directory.collapsed')
        for element in elements
            return unless keys.length
            label = @createLabel keys.shift()
            element.parentNode.insertBefore label, element

    toggleInTextEditors: (keys) ->
        @disposables.add atom.workspace.observeTextEditors (editor) =>
            editorView = atom.views.getView(editor)
            $editorView = $(editorView)
            return if $editorView.is ':not(:visible)'

            # 'jumpy-jump-mode is for keymaps and utilized by tests
            editorView.classList.add 'jumpy-jump-mode'

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

    toggle: ->
        nextKeys = _.clone keys
        @toggleInTextEditors nextKeys

    destroy: ->
        decoration.getMarker().destroy() for decoration in @decorations
        @decorations = [] # Very important for GC.
        # Verifiable in Dev Tools -> Timeline -> Nodes.

    findLocation: (firstChar, secondChar) ->
        label = "#{firstChar}#{secondChar}"
        return @allPositions[label] if label of @allPositions
        null

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

module.exports = Labels
