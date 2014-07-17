{View} = require 'atom'
{$} = require 'atom'
_ = require 'lodash'

characters =
    (String.fromCharCode(a) for a in ['a'.charCodeAt()..'z'.charCodeAt()])
keys = []
for c1 in characters
    for c2 in characters
        keys.push c1 + c2

module.exports =
class JumpyView extends View

    @content: ->
        @div ''

    initialize: (serializeState) ->
        atom.workspaceView.command "jumpy:toggle", => @toggle()
        atom.workspaceView.command "jumpy:clear", => @clear()
        that = this
        for c in characters
            atom.workspaceView.command "jumpy:#{c}", (c) -> that.getKey(c)
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
        that = this
        nextKeys = _.clone keys
        atom.workspaceView.eachEditorView (editorView) ->
            return if !editorView.active
            editorView.addClass 'jumpy-jump-mode'
            editorView.find '.scroll-view .overlayer'
                .append "<div class='jumpy labels'></div>"

            atom.workspaceView.find '*'
                .on 'click scroll', (e) ->
                    that.clear()

            isScreenRowVisible = (lineNumber) ->
                return lineNumber > editorView.getFirstVisibleScreenRow() &&
                    lineNumber < editorView.getLastVisibleScreenRow()
            wordsPattern = /([\w]){2,}/g
            for line, lineNumber in editorView.getEditor().buffer.lines
                if line != ''
                    while ((word = wordsPattern.exec(line)) != null)
                        if isScreenRowVisible lineNumber + 1
                            keyLabel = nextKeys.shift()
                            position = {row: lineNumber, column: word.index}
                            # creates a reference:
                            that.allPositions[keyLabel] = {
                                editor: editorView.getEditor().id
                                position: position
                            }
                            pixelPosition = editorView
                                .pixelPositionForBufferPosition [lineNumber,
                                word.index]
                            labelElement =
                                $("<div class='jumpy label'>#{keyLabel}</div>")
                                    .css {
                                        left: pixelPosition.left
                                        top: pixelPosition.top
                                    }
                            editorView.find ".jumpy.labels"
                                .append labelElement

    clear: ->
        @clearJumpMode()
