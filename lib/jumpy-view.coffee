{View} = require 'atom'
{$} = require 'atom'
_ = require 'lodash'

characters =
    (String.fromCharCode(a) for a in ['a'.charCodeAt()..'z'.charCodeAt()])
keys = []
for c1 in characters
    for c2 in characters
        keys.push c1 + c2

wordsPattern = /([\w]){2,}/g

module.exports =
class JumpyView extends View

    @content: ->
        @div ''

    initialize: (serializeState) ->
        atom.workspaceView.command 'jumpy:toggle', => @toggle()
        atom.workspaceView.command 'jumpy:reset', => @reset()
        atom.workspaceView.command 'jumpy:clear', => @clear()
        for c in characters
            atom.workspaceView.command "jumpy:#{c}", (c) => @getKey c
        # TODO: consider moving this into toggle for new bindings.
        @backedUpKeyBindings = _.clone atom.keymap.keyBindings
        atom.workspaceView.statusBar?.prependLeft(
            '<div id="status-bar-jumpy" class="inline-block"></div>')

    getKey: (character) ->
        character = character.type.charAt(character.type.length - 1)
        if not @firstChar
            @firstChar = character
            atom.workspaceView.statusBar?.find '#status-bar-jumpy #status'
                .html @firstChar
            atom.workspaceView.eachEditorView (editorView) =>
                for label in editorView.find '.jumpy.label'
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
        atom.workspaceView.eachEditorView (editorView) ->
            editorView.find '.irrelevant'
                .removeClass 'irrelevant'
        atom.workspaceView.statusBar?.find '#status-bar-jumpy #status'
            .html 'Jump Mode!'

    clear: ->
        @clearJumpMode()

    turnOffSlowKeys: ->
        atom.keymap.keyBindings = atom.keymap.keyBindings.filter (keymap) ->
            keymap.command.indexOf('jumpy') > -1

    toggle: ->
        fontSize = atom.config.get 'jumpy.fontSize'
        fontSize = .75 if isNaN(fontSize) or fontSize > 1
        fontSize = (fontSize * 100) + '%'
        highContrast = atom.config.get 'jumpy.highContrast'

        @turnOffSlowKeys()
        atom.workspaceView.statusBar?.find '#status-bar-jumpy'
            .html 'Jumpy: <span id="status">Jump Mode!</span>'

        @allPositions = {}
        atom.workspaceView.find '*'
            .on 'mousedown scroll', (e) =>
                @clear()
        nextKeys = _.clone keys
        atom.workspaceView.eachEditorView (editorView) =>
            return if !editorView.active
            editorView.addClass 'jumpy-jump-mode'
            $labels = editorView.find '.scroll-view .overlayer'
                .append '<div class="jumpy labels"></div>'

            firstVisibleRow = editorView.getFirstVisibleScreenRow()
            lastVisibleRow = editorView.getLastVisibleScreenRow()
            editor = editorView.getEditor()

            drawLabels = (column) =>
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
                $labels
                    .append labelElement

            for lineNumber in [firstVisibleRow...lastVisibleRow]
                lineContents = editor.lineForScreenRow(lineNumber).text
                if editor.isFoldedAtScreenRow(lineNumber)
                    drawLabels 0
                else
                    while ((word = wordsPattern.exec(lineContents)) != null)
                        drawLabels word.index

    clearJumpMode: ->
        @clearKeys()
        $('#status-bar-jumpy').html ''
        atom.workspaceView.eachEditorView (e) ->
            e.find('.jumpy').remove()
            e.removeClass 'jumpy-jump-mode'
        atom.keymap.keyBindings = @backedUpKeyBindings
        @detach()

    jump: ->
        location = @findLocation()
        if location == null
            console.log "Jumpy canceled jump.  No location found."
            return
        useHomingBeacon = atom.config.get 'jumpy.useHomingBeaconEffectOnJumps'
        atom.workspaceView.eachEditorView (editorView) =>
            currentEditor = editorView.getEditor()
            if currentEditor.id != location.editor
                return

            pane = editorView.getPane()
            pane.activate()
            isVisualMode = editorView.view().hasClass 'visual-mode'
            if isVisualMode || (currentEditor.getSelections().length == 1 && currentEditor.getSelectedText() != '')
                currentEditor.selectToScreenPosition(location.position)
            else
                currentEditor.setCursorScreenPosition location.position
            if useHomingBeacon
                cursor = pane.find '.cursors .cursor'
                cursor.addClass 'beacon'
                setTimeout ->
                    cursor.removeClass 'beacon'
                , 150
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
        console.log 'Jumpy: "destroy" called. Detaching.'
        @clearJumpMode()
        @detach()
