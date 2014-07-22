JumpyView = require './jumpy-view'

module.exports =
    jumpyView: null

    activate: (state) ->
        @jumpyView = new JumpyView(state.jumpyViewState)

    deactivate: ->
        @jumpyView.destroy()

    serialize: ->
        jumpyViewState: @jumpyView.serialize()
