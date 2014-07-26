JumpyView = require './jumpy-view'

module.exports =
    jumpyView: null
    configDefaults:
        fontSize: .75
        highContrast: false

    activate: (state) ->
        @jumpyView = new JumpyView state.jumpyViewState

    deactivate: ->
        @jumpyView.destroy()

    serialize: ->
        jumpyViewState: @jumpyView.serialize()
