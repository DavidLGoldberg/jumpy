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

    initialize: (serializeState) ->
        @disposables = new CompositeDisposable()

        atom.commands.add 'atom-workspace',
            'jumpy:toggle': => @toggle()
            'jumpy:reset': => @reset()
            'jumpy:clear': => @clearJumpMode()

        commands = {}
        for characterSet in [lowerCharacters, upperCharacters]
            for c in characterSet
                do (c) => commands['jumpy:' + c] = => @getKey(c)
        atom.commands.add 'atom-workspace', commands

        # TODO: consider moving this into toggle for new bindings.
        @backedUpKeyBindings = _.clone atom.keymap.keyBindings

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
            @disposables.add atom.workspace.observeTextEditors (editor) ->
                editorView = atom.views.getView(editor)
                return if editorView.style.display is 'none'

                $(editorView).find('.label:not(.irrelevant)').each (i, label) ->
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
                return if editorView.style.display is 'none'

                for label in editorView.querySelectorAll '.jumpy.label'
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
            $(editorView).find '.irrelevant'
                .removeClass 'irrelevant'
        @statusBarJumpy?.classList.remove 'no-match'
        @statusBarJumpyStatus?.innerHTML = 'Jump Mode!'

    initKeyFilters: ->
        @filteredJumpyKeys = @getFilteredJumpyKeys()
        Object.observe atom.keymap.keyBindings, ->
            @filteredJumpyKeys = @getFilteredJumpyKeys()
        # Don't think I need a corresponding unobserve

    getFilteredJumpyKeys: ->
        atom.keymap.keyBindings.filter (keymap) ->
            keymap.command.indexOf('jumpy') > -1

    turnOffSlowKeys: ->
        atom.keymap.keyBindings = @filteredJumpyKeys

    toggle: ->
        @clearJumpMode()

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
            return if editorView.style.display is 'none'

            $editorView = $(editorView)
            $editorView
                .addClass 'jumpy-jump-mode'
                .find '.overlayer'
                .append '<div class="jumpy jumpy-label-container"></div>'
            $labelContainer = $editorView.find('.jumpy-label-container')

            drawLabels = (column, $labelContainer) =>
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
                            left: pixelPosition.left
                            top: pixelPosition.top
                            fontSize: fontSize
                if highContrast
                    labelElement.addClass 'high-contrast'
                $labelContainer
                    .append labelElement

            [firstVisibleRow, lastVisibleRow] = editor.getVisibleRowRange()
            for lineNumber in [firstVisibleRow...lastVisibleRow]
                lineContents = editor.lineTextForScreenRow(lineNumber)
                if editor.isFoldedAtScreenRow(lineNumber)
                    drawLabels 0, $labelContainer
                else
                    while (word = wordsPattern.exec(lineContents))

                        if word.length == 1
                            drawLabels word.index, $labelContainer

                        # Check if we have at least 1 non-undefined match group.
                        hasGroupMatches = false
                        for i in [1...word.length]
                            if word[i]
                                hasGroupMatches = true
                                break

                        if !hasGroupMatches
                            drawLabels word.index, $labelContainer
                            continue

                        matchStr = word[0]

                        for i in [1...word.length]
                            offset = matchStr.indexOf(word[i])
                            if offset != -1
                                drawLabels(word.index + offset, $labelContainer)


            @initializeClearEvents(editor, editorView)

    initializeClearEvents: (editor, editorView) ->
        $(@workspaceElement).find '*'
            .on 'mousedown', =>
                @clearJumpMode()

        @disposables.add editor.onDidChangeScrollTop =>
            @clearJumpMode()
        @disposables.add editor.onDidChangeScrollLeft =>
            @clearJumpMode()

        editorView.onblur = =>
            @clearJumpMode()

    clearJumpMode: ->
        @clearKeys()
        @statusBarJumpy?.innerHTML = ''
        @disposables.add atom.workspace.observeTextEditors (editor) ->
            editorView = atom.views.getView(editor)
            $(editorView).find('.jumpy').remove()
            editorView.classList.remove 'jumpy-jump-mode'
        atom.keymap.keyBindings = @backedUpKeyBindings
        @disposables?.dispose()
        @detach()

    jump: ->
        location = @findLocation()
        if location == null
            console.log "Jumpy canceled jump.  No location found."
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

            # FIXME: Restore homing beacon code below!
            # Unfortunately I NEED to release 2.0 without this as shadow-dom
            # has been enabled by default.

            # useHomingBeacon = atom.config.get 'jumpy.useHomingBeaconEffectOnJumps'
            # if useHomingBeacon
            #     debugger
            #     cursor = pane.querySelector '.cursors .cursor'
            #     cursor.classList.add 'beacon'
            #     setTimeout ->
            #         cursor.classList.remove 'beacon'
            #     , 150
            console.log "Jumpy jumped to: #{@firstChar}#{@secondChar} at " +
                "(#{location.position.row},#{location.position.column})"

    findLocation: ->
        label = "#{@firstChar}#{@secondChar}"
        if label of @allPositions
            return @allPositions[label]

        return null

    # Returns an object that can be retrieved when package is activated
    serialize: ->

    # Tear down any state and detach
    destroy: ->
        console.log 'Jumpy: "destroy" called.'
        @clearJumpMode()
