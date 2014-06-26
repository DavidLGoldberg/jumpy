{View} = require 'atom'

module.exports =
class JumpyView extends View
  @content: ->
    @div class: 'jumpy overlay from-top', =>
      @div "The Jumpy package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "jumpy:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "JumpyView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
