JumpyView = require './jumpy-view'

module.exports =
    jumpyView: null
    config:
        fontSize:
            type: 'number'
            default: .75
            minimum: 0
            maximum: 1
        highContrast:
            type: 'boolean'
            default: false
        useHomingBeaconEffectOnJumps:
            type: 'boolean'
            default: true
        matchPattern:
            type: 'string'
            default: '([A-Z]+([0-9a-z])*)|[a-z0-9]{2,}'

    activate: (state) ->
        @jumpyView = new JumpyView state.jumpyViewState

    deactivate: ->
        @jumpyView.destroy()

    serialize: ->
        jumpyViewState: @jumpyView.serialize()
