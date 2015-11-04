# Shortly after 2.0 release action items:
# (need to rush release a little bit because
# the default shadow dom option has been enabled by atom!)
# FIXME: Beacon code (currently broken in shadow).  This will probably return
# in the form of a decoration with a "flash", not sure yet.
# TODO: Merge in @willdady's code for better accuracy.
# TODO: Investigate using markers, else my own custom elements.
# TODO: Remove space-pen? Probably alongside markers todo above.

{CompositeDisposable} = require 'atom'
{View, $} = require 'space-pen'
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

module.exports =
class JumpyView extends View

    @content: ->
        @div ''

    getOverlayer: (editorView) ->
        editorView.shadowRoot.querySelector('content[select=".overlayer"]')

    initialize: (serializeState) ->
        @disposables = new CompositeDisposable()
        @commands = new CompositeDisposable()

        @commands.add atom.commands.add 'atom-workspace',
            'jumpy:toggle': => @toggle()
            'jumpy:reset': => @reset()
            'jumpy:clear': => @clearJumpMode()

        commands = {}
        for characterSet in [lowerCharacters, upperCharacters]
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

        @initKeyFilters()

    getKey: (character) ->
        @statusBarJumpy?.classList.remove 'no-match'

        isMatchOfCurrentLabels = (character, labelPosition) =>
            found = false
            @disposables.add atom.workspace.observeTextEditors (editor) =>
                editorView = atom.views.getView(editor)
                return if $(editorView).is ':not(:visible)'

                overlayer = @getOverlayer editorView
                $(overlayer).find('.label:not(.irrelevant)').each (i, label) ->
                    if label.innerHTML[labelPosition] == character
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

                overlayer = @getOverlayer editorView
                for label in overlayer.querySelectorAll '.jumpy.label'
                    if label.innerHTML.indexOf(@firstChar) != 0
                        label.classList.add 'irrelevant'
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
        @disposables.add atom.workspace.observeTextEditors (editor) =>
            editorView = atom.views.getView(editor)
            overlayer = @getOverlayer editorView
            $(overlayer).find '.irrelevant'
                .removeClass 'irrelevant'
        @statusBarJumpy?.classList.remove 'no-match'
        @statusBarJumpyStatus?.innerHTML = 'Jump Mode!'

    initKeyFilters: ->
        @filteredJumpyKeys = @getFilteredJumpyKeys()
        Object.observe atom.keymaps.keyBindings, ->
            @filteredJumpyKeys = @getFilteredJumpyKeys()
        # Don't think I need a corresponding unobserve

    getFilteredJumpyKeys: ->
        atom.keymaps.keyBindings.filter (keymap) ->
            keymap.command
                .indexOf('jumpy') > -1 if typeof keymap.command is 'string'

    turnOffSlowKeys: ->
        atom.keymaps.keyBindings = @filteredJumpyKeys

    toggle: ->
        @clearJumpMode()

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
        nextKeys = _.clone keys
        @disposables.add atom.workspace.observeTextEditors (editor) =>
            editorView = atom.views.getView(editor)
            $editorView = $(editorView)
            return if $editorView.is ':not(:visible)'

            editorView.classList.add 'jumpy-jump-mode'
            overlayer = @getOverlayer editorView
            $(overlayer)
                .append '<div class="jumpy jumpy-label-container"></div>'
            labelContainer = overlayer.querySelector '.jumpy-label-container'

            drawLabels = (column, labelContainer, scrollLeft, scrollTop) =>
                return unless nextKeys.length

                keyLabel = nextKeys.shift()
                position = {row: lineNumber, column: column}
                # creates a reference:
                @allPositions[keyLabel] = {
                    editor: editor.id
                    position: position
                }
                pixelPosition = editorView
                    .pixelPositionForScreenPosition [lineNumber,
                    column]
                labelElement =
                    $("<div class='jumpy label'>#{keyLabel}</div>")
                        .css
                            left: pixelPosition.left - scrollLeft
                            top: pixelPosition.top - scrollTop
                            fontSize: fontSize
                if highContrast
                    labelElement.addClass 'high-contrast'
                $(labelContainer)
                    .append labelElement

            [firstVisibleRow, lastVisibleRow] = editor.getVisibleRowRange()
            scrollLeft = editor.getScrollLeft()
            scrollTop = editor.getScrollTop()
            for lineNumber in [firstVisibleRow...lastVisibleRow]
                lineContents = editor.lineTextForScreenRow(lineNumber)
                if editor.isFoldedAtScreenRow(lineNumber)
                    drawLabels 0, labelContainer, scrollLeft, scrollTop
                else
                    while ((word = wordsPattern.exec(lineContents)) != null)
                        drawLabels word.index, labelContainer,
                            scrollLeft, scrollTop

            @initializeClearEvents(editor, editorView)

    clearJumpModeHandler: (e) =>
        @clearJumpMode()

    initializeClearEvents: (editor, editorView) ->
        @disposables.add editor.onDidChangeScrollTop =>
            @clearJumpModeHandler()
        @disposables.add editor.onDidChangeScrollLeft =>
            @clearJumpModeHandler()

        for e in ['blur', 'click']
            editorView.addEventListener e, @clearJumpModeHandler, true

    clearJumpMode: ->
        if @cleared
            return

        @cleared = true
        @clearKeys()
        @statusBarJumpy?.innerHTML = ''
        @disposables.add atom.workspace.observeTextEditors (editor) =>
            editorView = atom.views.getView(editor)
            return if $(editorView).is ':not(:visible)'
            overlayer = @getOverlayer editorView
            $(overlayer).find('.jumpy').remove()
            editorView.classList.remove 'jumpy-jump-mode'
            for e in ['blur', 'click']
                editorView.removeEventListener e, @clearJumpModeHandler, true
        atom.keymaps.keyBindings = @backedUpKeyBindings
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

            useHomingBeacon =
                atom.config.get 'jumpy.useHomingBeaconEffectOnJumps'
            if useHomingBeacon
                cursor = editorView.shadowRoot.querySelector '.cursors .cursor'
                if cursor
                    cursor.classList.add 'beacon'
                    setTimeout ->
                        cursor.classList.remove 'beacon'
                    , 150

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
