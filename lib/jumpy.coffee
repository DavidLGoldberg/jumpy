JumpyView = require './jumpy-view'

module.exports =
    jumpyView: null
    configDefaults:
        fontSize: .75
        highContrast: false
        useHomingBeaconEffectOnJumps: true # Needs react editor
        matchPattern: '([A-Z]+([0-9a-z])*)|[a-z0-9]{2,}'

    activate: (state) ->
        @jumpyView = new JumpyView state.jumpyViewState

    deactivate: ->
        @jumpyView.destroy()

    serialize: ->
        jumpyViewState: @jumpyView.serialize()
