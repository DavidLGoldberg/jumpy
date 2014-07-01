{View} = require 'atom'
{$} = require 'atom'

characters = (String.fromCharCode(a) for a in ['a'.charCodeAt()..'z'.charCodeAt()])

module.exports =
class JumpyView extends View
  @jumpMode = false

  @content: ->
    @div '', class: 'jumpy label'

  initialize: (serializeState) ->
    atom.workspaceView.command "jumpy:toggle", => @toggle()
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
          @jump()
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
      console.log "Jumpy jumped to: #{@firstChar}#{@secondChar}"

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    @jumpMode = !@jumpMode

    if @hasParent()
      @detach()

    if @jumpMode
      $('#status-bar-jumpy').html("Jumpy: Jump Mode!")
      atom.workspaceView.eachEditorView (e) -> e.addClass 'jumpy-specificity-1 jumpy-specificity-2 jumpy-jump-mode'

      relevantClasses = ['variable', 'keyword', 'method', 'string.quoted']
      atom.workspaceView.find((".line .source .#{c}" for c in relevantClasses).join()).prepend(this)

      keys = []
      for c1 in characters
        for c2 in characters
          keys.push c1 + c2

      for label in atom.workspaceView.find(".jumpy.label")
          $(label).html(keys.shift())
    else
        @clearJumpMode()
