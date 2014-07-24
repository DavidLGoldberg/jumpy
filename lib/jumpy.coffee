JumpyView = require './jumpy-view'

module.exports =
    jumpyView: null
    configDefaults:
        fontSize: .75
        highContrast: false
        useHomingBeaconEffectOnJumps: true # Needs react editor

    activate: (state) ->
        @jumpyView = new JumpyView state.jumpyViewState

    deactivate: ->
        @jumpyView.destroy()

    serialize: ->
        jumpyViewState: @jumpyView.serialize()
