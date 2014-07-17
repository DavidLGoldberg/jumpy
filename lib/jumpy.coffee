JumpyView = require './jumpy-view'

module.exports =
    jumpyView: null

    activate: (state) ->
        @jumpyView = new JumpyView(state.jumpyViewState)
        atom.workspaceView.statusBar?.prependLeft("<div id='status-bar-jumpy' class='inline-block' style='color:red;'></div>")

    deactivate: ->
        @jumpyView.destroy()

    serialize: ->
        jumpyViewState: @jumpyView.serialize()
