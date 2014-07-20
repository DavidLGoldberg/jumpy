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
        atom.workspaceView.command "jumpy:toggle", => @toggle()
        atom.workspaceView.command "jumpy:clear", => @clear()
        for c in characters
            atom.workspaceView.command "jumpy:#{c}", (c) => @getKey(c)
        # TODO: consider moving this into toggle for new bindings.
        @backedUpKeyBindings = _.clone(atom.keymap.keyBindings)

    getKey: (character) ->
        character = character.type.charAt(character.type.length - 1)
        if not @firstChar
            @firstChar = character
        else if not @secondChar
            @secondChar = character

        if @secondChar
            @jump() # Jump first.  Currently need the placement of the labels.
            @clearJumpMode()

    clearKeys: ->
        @firstChar = null
        @secondChar = null

    clearJumpMode: ->
        @clearKeys()
        $('#status-bar-jumpy').html("")
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
        atom.workspaceView.eachEditorView (editorView) =>
            currentEditor = editorView.getEditor()
            if currentEditor.id == location.editor
                pane = editorView.getPane()
                pane.activate()
                currentEditor.setCursorBufferPosition(location.position)
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

    turnOffSlowKeys: ->
        atom.keymap.keyBindings = atom.keymap.keyBindings.filter (keymap) ->
            keymap.command.indexOf('jumpy') > -1

    toggle: ->
        @turnOffSlowKeys()
        $('#status-bar-jumpy').html "Jumpy: Jump Mode!"
        @allPositions = {}
        atom.workspaceView.find '*'
            .on 'click scroll', (e) =>
                @clear()
        nextKeys = _.clone keys
        atom.workspaceView.eachEditorView (editorView) =>
            return if !editorView.active
            editorView.addClass 'jumpy-jump-mode'
            $labels = editorView.find '.scroll-view .overlayer'
                .append "<div class='jumpy labels'></div>"

            firstVisibleRow = editorView.getFirstVisibleScreenRow()
            lastVisibleRow = editorView.getLastVisibleScreenRow()
            editor = editorView.getEditor()
            relevantLines = (editor.buffer.lines.map (line, lineNumber) ->
                {contents: line, lineNumber} ).filter (line) ->
                 line.contents != '' &&
                 line.lineNumber >= firstVisibleRow &&
                 line.lineNumber < lastVisibleRow
            for line in relevantLines
                while ((word = wordsPattern.exec(line.contents)) != null)
                    keyLabel = nextKeys.shift()
                    position = {row: line.lineNumber, column: word.index}
                    # creates a reference:
                    @allPositions[keyLabel] = {
                        editor: editor.id
                        position: position
                    }
                    pixelPosition = editorView
                        .pixelPositionForBufferPosition [line.lineNumber,
                        word.index]
                    labelElement =
                        $("<div class='jumpy label jump'>#{keyLabel}</div>")
                            .css {
                                left: pixelPosition.left
                                top: pixelPosition.top
                            }
                    $labels
                        .append labelElement

    clear: ->
        @clearJumpMode()
