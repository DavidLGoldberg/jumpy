# TODO: Merge in @johngeorgewright's code for treeview
# TODO: Merge in @willdady's code for better accuracy.
# TODO: Remove space-pen?

### global atom ###
{ CompositeDisposable } = require 'atom'
{ View, $ } = require 'space-pen'
_ = require 'lodash'

{ getCharacterSets, getKeySet, drawLabels, drawBeacon } = require('./label')

class JumpyView extends View

    @content: ->
        @div ''

    initialize: ->
        @disposables = new CompositeDisposable()
        @decorations = []
        @commands = new CompositeDisposable()

        @commands.add atom.commands.add 'atom-workspace',
            'jumpy:toggle': => @toggle()
            'jumpy:reset': => @reset()
            'jumpy:clear': => @clearJumpMode()

        commands = {}
        for characterSet in getCharacterSets()
            for c in characterSet
                do (c) => commands['jumpy:' + c] = => @getKey(c)
        @commands.add atom.commands.add 'atom-workspace', commands

        # TODO: consider moving this into toggle for new bindings.
        @backedUpKeyBindings = _.clone atom.keymaps.keyBindings

        @workspaceElement = atom.views.getView(atom.workspace)
        @statusBar = document.querySelector 'status-bar'
        @statusBar?.addLeftTile
            item: $('<div id="status-bar-jumpy" class="inline-block"></div>')
            priority: -1
        @statusBarJumpy = document.getElementById 'status-bar-jumpy'

    getKey: (character) ->
        @statusBarJumpy?.classList.remove 'no-match'

        isMatchOfCurrentLabels = (character, labelPosition) =>
            found = false
            @disposables.add atom.workspace.observeTextEditors (editor) =>
                editorView = atom.views.getView(editor)
                return if $(editorView).is ':not(:visible)'

                for decoration in @decorations
                    element = decoration.getProperties().item
                    if element.textContent[labelPosition] == character
                        found = true
                        return false
            return found

        # Assert: labelPosition will start at 0!
        labelPosition = (if not @firstChar then 0 else 1)
        if !isMatchOfCurrentLabels character, labelPosition
            @statusBarJumpy?.classList.add 'no-match'
            @statusBarJumpyStatus?.innerHTML = 'No match!'
            return

        if not @firstChar
            @firstChar = character
            @statusBarJumpyStatus?.innerHTML = @firstChar
            # TODO: Refactor this so not 2 calls to observeTextEditors
            @disposables.add atom.workspace.observeTextEditors (editor) =>
                editorView = atom.views.getView(editor)
                return if $(editorView).is ':not(:visible)'

                for decoration in @decorations
                    element = decoration.getProperties().item
                    if element.textContent.indexOf(@firstChar) != 0
                        element.classList.add 'irrelevant'
        else if not @secondChar
            @secondChar = character

        if @secondChar
            @jump() # Jump first.  Currently need the placement of the labels.
            @clearJumpMode()

    clearKeys: ->
        @firstChar = null
        @secondChar = null

    reset: ->
        @clearKeys()
        for decoration in @decorations
            decoration.getProperties().item.classList.remove 'irrelevant'
        @statusBarJumpy?.classList.remove 'no-match'
        @statusBarJumpyStatus?.innerHTML = 'Jump Mode!'

    getFilteredJumpyKeys: ->
        atom.keymaps.keyBindings.filter (keymap) ->
            keymap.command.includes 'jumpy' if typeof keymap.command is 'string'

    turnOffSlowKeys: ->
        atom.keymaps.keyBindings = @getFilteredJumpyKeys()

    toggle: ->
        # Set dirty for @clearJumpMode
        @cleared = false

        # TODO: Can the following few lines be singleton'd up? ie. instance var?
        wordsPattern = new RegExp (atom.config.get 'jumpy.matchPattern'), 'g'
        fontSize = atom.config.get 'jumpy.fontSize'
        fontSize = .75 if isNaN(fontSize) or fontSize > 1
        fontSize = (fontSize * 100) + '%'
        highContrast = atom.config.get 'jumpy.highContrast'

        @turnOffSlowKeys()
        @statusBarJumpy?.classList.remove 'no-match'
        @statusBarJumpy?.innerHTML =
            'Jumpy: <span class="status">Jump Mode!</span>'
        @statusBarJumpyStatus =
            document.querySelector '#status-bar-jumpy .status'

        @allPositions = {}
        keys = getKeySet()
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

            settings = { keys, highContrast, fontSize }
            [minColumn, maxColumn] = getVisibleColumnRange editorView
            rows = editor.getVisibleRowRange()
            if rows
                [firstVisibleRow, lastVisibleRow] = rows
                # TODO: Right now there are issues with lastVisbleRow
                for lineNumber in [firstVisibleRow...lastVisibleRow]
                    lineContents = editor.lineTextForScreenRow(lineNumber)
                    if editor.isFoldedAtScreenRow(lineNumber)
                        @decorations.push drawLabels editor,
                            @allPositions, lineNumber, 0, settings
                    else
                        while ((word = wordsPattern.exec(lineContents)) != null)
                            column = word.index
                            # Do not do anything... markers etc.
                            # if the columns are out of bounds...
                            if column > minColumn && column < maxColumn
                                @decorations.push drawLabels editor,
                                    @allPositions, lineNumber, column, settings

            @initializeClearEvents(editorView)

    clearJumpModeHandler: =>
        @clearJumpMode()

    initializeClearEvents: (editorView) ->
        @disposables.add editorView.onDidChangeScrollTop =>
            @clearJumpModeHandler()
        @disposables.add editorView.onDidChangeScrollLeft =>
            @clearJumpModeHandler()

        for e in ['blur', 'click']
            editorView.addEventListener e, @clearJumpModeHandler, true

    clearJumpMode: ->
        clearAllMarkers = =>
            for decoration in @decorations
                decoration.getMarker().destroy()
            @decorations = [] # Very important for GC.
            # Verifiable in Dev Tools -> Timeline -> Nodes.

        if @cleared
            return

        @cleared = true
        @clearKeys()
        @statusBarJumpy?.innerHTML = ''
        @disposables.add atom.workspace.observeTextEditors (editor) =>
            editorView = atom.views.getView(editor)

            editorView.classList.remove 'jumpy-jump-mode'
            for e in ['blur', 'click']
                editorView.removeEventListener e, @clearJumpModeHandler, true
        atom.keymaps.keyBindings = @backedUpKeyBindings
        clearAllMarkers()
        @disposables?.dispose()
        @detach()

    jump: ->
        location = @findLocation()
        if location == null
            return
        @disposables.add atom.workspace.observeTextEditors (currentEditor) ->
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
                drawBeacon currentEditor, location

    findLocation: ->
        label = "#{@firstChar}#{@secondChar}"
        if label of @allPositions
            return @allPositions[label]

        return null

    # Returns an object that can be retrieved when package is activated
    serialize: ->

    # Tear down any state and detach
    destroy: ->
        @commands?.dispose()
        @clearJumpMode()

module.exports = JumpyView
