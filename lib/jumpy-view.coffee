{View} = require 'atom'
{$} = require 'atom'
_ = require 'lodash'

characters = (String.fromCharCode(a) for a in ['a'.charCodeAt()..'z'.charCodeAt()])

module.exports =
class JumpyView extends View
  @content: ->
    @div '', class: 'jumpy label'

  initialize: (serializeState) ->
    @pixels = @getAllPixelLocations()
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
      atom.workspaceView.eachEditorView (e) -> e.removeClass 'jumpy-specificity-1 jumpy-specificity-2 jumpy-jump-mode'
      atom.workspaceView.find('.jumpy').remove()
      @detach()

  jump: ->
      location = @findLocation()
      if location == null
          return
      editor = atom.workspaceView.getActivePaneItem()
      editor.setCursorBufferPosition(location)
      console.log "Jumpy jumped to: #{@firstChar}#{@secondChar}"

  findLocation: ->
      nearest10 = (val) ->
          Math.round(val / 10) * 10

      labelElement = atom.workspaceView.find(".jumpy.#{@firstChar}#{@secondChar}").get(0)
      labelLocation = labelElement.getBoundingClientRect()
      lines = atom.workspaceView.find('.lines')
      offsetTop = lines.get(0).offsetTop
      #offsetLeft = lines.offset().left
      offsetLeft = 0
      for line, lineIndex in @pixels
          line = _.compact line
          for char, charIndex in line
              #console.log lineIndex, charIndex, char, nearest10(labelLocation.left), nearest10(labelLocation.top)
              if nearest10(labelLocation.left) == char.left + 270 + offsetLeft && nearest10(labelLocation.bottom - labelLocation.height) == char.top + 40 + offsetTop
                  return [lineIndex, charIndex]

      return null

  getAllPixelLocations: ->
      pixels = []
      for line, lineIndex in atom.workspaceView.getActivePaneItem().buffer.lines
          pixels.push([])
          for char, charIndex in line
              pixelPosition = atom.workspaceView.getActiveView().pixelPositionForBufferPosition([lineIndex, charIndex])
              pixels[lineIndex][charIndex] = pixelPosition unless pixelPosition.left == 0 && pixelPosition.top == 0

      return pixels

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    if @hasParent()
      @detach()

    $('#status-bar-jumpy').html("Jumpy: Jump Mode!")
    atom.workspaceView.eachEditorView (e) -> e.addClass 'jumpy-specificity-1 jumpy-specificity-2 jumpy-jump-mode'

    relevantClasses = ['variable', 'keyword', 'method', 'string.quoted']
    atom.workspaceView.find((".line .source .#{c}" for c in relevantClasses).join()).prepend(this)

    keys = []
    for c1 in characters
      for c2 in characters
          keys.push c1 + c2

    for label in atom.workspaceView.find(".jumpy.label")
        key = keys.shift()
        $(label)
            .html(key)
            .addClass(key)

  clear: ->
      @clearJumpMode()
