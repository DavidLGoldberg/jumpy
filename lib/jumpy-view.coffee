{View} = require 'atom'
{$} = require 'atom'
_ = require 'lodash'

characters = (String.fromCharCode(a) for a in ['a'.charCodeAt()..'z'.charCodeAt()])
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
          e.removeClass 'jumpy-specificity-1 jumpy-specificity-2 jumpy-jump-mode'
      @detach()

  jump: ->
      location = @findLocation()
      if location == null
          console.log "Jumpy canceled jump.  No location found."
          return
      editor = atom.workspace.getActivePaneItem()
      editor.setCursorBufferPosition(location)
      console.log "Jumpy jumped to: #{@firstChar}#{@secondChar} at (#{location.row},#{location.column})"

  findLocation: ->
      label = "#{@firstChar}#{@secondChar}"
      for editor in atom.workspaceView.getEditorViews()
          currentId = editor.find('.jumpy.labels').attr('jumpyid')
          if label of @allPositions[currentId]
              return @allPositions[currentId][label]

      return null

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    console.log 'Jumpy: "destroy" called. Detaching.'
    @clearJumpMode()
    @detach()

  toggle: ->
    $('#status-bar-jumpy').html("Jumpy: Jump Mode!")
    @allPositions = {}
    that = this
    nextKeys = _.clone keys
    atom.workspaceView.eachEditorView (e) ->
        return if !e.active
        e.addClass 'jumpy-specificity-1 jumpy-specificity-2 jumpy-jump-mode'
        e.find('.scroll-view .overlayer').append("<div class='jumpy labels' jumpyid='#{e.id}'></div>")
        positions = {}
        that.allPositions[e.id] = positions

        wordsPattern = /([\w]){2,}/g
        for line, lineNumber in atom.workspace.getActivePaneItem().buffer.lines
            if line != ''
                while ((word = wordsPattern.exec(line)) != null)
                    keyLabel = nextKeys.shift()
                    positions[keyLabel] = {row: lineNumber, column: word.index}
                    pixelPosition = e.pixelPositionForBufferPosition([lineNumber, word.index])
                    labelElement = $("<div class='jumpy label'>#{keyLabel}</div>")
                        .css({left: pixelPosition.left, top: pixelPosition.top})
                    e.find(".jumpy.labels").append(labelElement)

  clear: ->
      @clearJumpMode()
