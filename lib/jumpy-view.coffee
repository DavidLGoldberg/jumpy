{View} = require 'atom'
{$} = require 'atom'

module.exports =
class JumpyView extends View
  @jumpMode = false
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
    @jumpMode = !@jumpMode
    $('#status-bar-jumpy').html(if @jumpMode then "Jumpy: Jump Mode!" else "")

    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
