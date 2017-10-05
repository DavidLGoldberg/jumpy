# TODO: Merge in @johngeorgewright's code for treeview
# TODO: Merge in @willdady's code for better accuracy.
# TODO: Remove space-pen?

### global atom ###
{ CompositeDisposable } = require 'atom'
{ View, $ } = require 'space-pen'
_ = require 'lodash'
mobx = require 'mobx'

{ getCharacterSets, getKeySet, drawLabels, drawBeacon } = require('./label')

class JumpyView extends View

    @content: ->
        @div ''

    initialize: ->
        @disposables = new CompositeDisposable()
        @mobxDisposables = []
        @decorations = []
        @commands = new CompositeDisposable()

        @commands.add atom.commands.add 'atom-workspace',
            'jumpy:toggle': => @toggle()
            'jumpy:reset': => @mobJumpy.reset()
            'jumpy:clear': => @clearJumpMode()

        commands = {}
        for characterSet in getCharacterSets()
            for c in characterSet
                do (c) => commands['jumpy:' + c] = => @getKey(c)
        @commands.add atom.commands.add 'atom-workspace', commands

        # TODO: consider moving this into toggle or mobx observables
        @backedUpKeyBindings = _.clone atom.keymaps.keyBindings

        @workspaceElement = atom.views.getView(atom.workspace)
        @statusBar = document.querySelector 'status-bar'
        @statusBar?.addLeftTile
            item: $('<div id="status-bar-jumpy" class="inline-block"></div>')
            priority: -1
        @statusBarJumpy = document.getElementById 'status-bar-jumpy'

        mobx.useStrict(true)
        @mobJumpy = mobx.observable(
            # global
            statusBarJumpy: @statusBarJumpy

            # Labels -----------------
            allPositions: mobx.asMap({})
            setPositions: ->
                mobx.action (key, value) =>
                    @allPositions.set key, value
            relevantPositions: -> # not necessarily reflected whith a 'no match'
                mobx.computed =>
                    mobx.asMap(@allPositions.entries().filter ([key]) =>
                        key.startsWith @currentKeys)
            clearAllPositions: mobx.action ->
                @allPositions.clear()

            # Input -----------------
            currentKeys: ''
            statusMessage: 'Jump Mode!'
            acceptKey: ->
                mobx.action (character) =>
                    @currentKeys += character

                    @statusBarJumpy?.classList.remove 'no-match'
                    @setStatusMessage @currentKeys
                    if !@isMatch.get()
                        @statusBarJumpy?.classList.add 'no-match'
                        @setStatusMessage 'No match!'
            isMatch: ->
                mobx.computed =>
                    @allPositions.entries().find ([key]) =>
                        key.startsWith @currentKeys
            removeKey: ->
                mobx.action ->
                    @currentKeys = @currentKeys[...-1]
            setStatusMessage: ->
                mobx.action (message) ->
                    @statusMessage = message
            reset: mobx.action =>
                @statusBarJumpy?.classList.remove 'no-match'
                @mobJumpy.clearKeys()
                for decoration in @decorations
                    decoration.getProperties().item
                        .classList.remove 'irrelevant'
            clearKeys: mobx.action ->
                @currentKeys = ''
                @statusMessage = 'Jump Mode!'
                @statusBarJumpy?.innerHTML = ''
        )

        @mobxDisposables.push mobx.autorun =>
            @statusBarJumpy.innerHTML = 'Jumpy: <span class="status">' +
                @mobJumpy.statusMessage +
            '</span>'

    getFilteredJumpyKeys: ->
        atom.keymaps.keyBindings.filter (keymap) ->
            keymap.command.includes 'jumpy' if typeof keymap.command is 'string'

    turnOffSlowKeys: ->
        atom.keymaps.keyBindings = @getFilteredJumpyKeys()

    getKey: (character) ->
        @mobJumpy.acceptKey(character)

        # TODO: Refactor this so not 2 calls to observeTextEditors
        @disposables.add atom.workspace.observeTextEditors (editor) =>
            editorView = atom.views.getView(editor)
            return if $(editorView).is ':not(:visible)'

            if !@mobJumpy.isMatch.get() # no match so
                @mobJumpy.removeKey(character) # ignore it.
            else # is a match so remove some irrelevant labels:
                for decoration in @decorations
                    element = decoration.getProperties().item
                    if !element.textContent.startsWith(@mobJumpy.currentKeys)
                        element.classList.add 'irrelevant'

            if @mobJumpy.currentKeys.length == 2
                @jump()
                @clearJumpMode()

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
                            @mobJumpy.setPositions, lineNumber, 0, settings
                    else
                        while ((word = wordsPattern.exec(lineContents)) != null)
                            column = word.index
                            # Do not do anything... markers etc.
                            # if the columns are out of bounds...
                            if column > minColumn && column < maxColumn
                                @decorations.push drawLabels editor,
                                    @mobJumpy.setPositions, lineNumber,
                                    column, settings

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
        @mobJumpy.clearKeys()
        clearAllMarkers = =>
            for decoration in @decorations
                decoration.getMarker().destroy()
            @decorations = [] # Very important for GC.
            # Verifiable in Dev Tools -> Timeline -> Nodes.

        if @cleared
            return

        @cleared = true
        @disposables.add atom.workspace.observeTextEditors (editor) =>
            editorView = atom.views.getView(editor)

            editorView.classList.remove 'jumpy-jump-mode'
            for e in ['blur', 'click']
                editorView.removeEventListener e, @clearJumpModeHandler, true
        atom.keymaps.keyBindings = @backedUpKeyBindings
        clearAllMarkers()
        @disposables?.dispose()
        @detach()

    jump: -> # TODO take an editor to avoid multiple observeTextEditors
        @mobJumpy.setStatusMessage "Jump mode!"
        label = @mobJumpy.currentKeys
        if !@mobJumpy.allPositions.has label
            return

        location = @mobJumpy.allPositions.get label

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

    # Returns an object that can be retrieved when package is activated
    serialize: ->

    # Tear down any state and detach
    destroy: ->
        mobxDisposable() for mobxDisposable in @mobxDisposables
        @commands?.dispose()
        @clearJumpMode()

module.exports = JumpyView
