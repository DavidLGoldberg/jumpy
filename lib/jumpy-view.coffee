{View} = require 'atom'
{$} = require 'atom'

module.exports =
class JumpyView extends View
  @jumpMode = false
  @content: ->
    @div "aa", class: 'jumpy label'

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

    if @jumpMode
      relevantClasses = ['variable', 'keyword', 'method', 'string.quoted']
      atom.workspaceView.find((".line .source .#{c}" for c in relevantClasses).join()).prepend(this)
    else
      atom.workspaceView.find('.jumpy').remove()
      @detach()
