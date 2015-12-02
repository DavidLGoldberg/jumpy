JumpyView = require './jumpy-view'

module.exports =
    jumpyView: null
    config:
        fontSize:
            description: 'The font size of jumpy labels.'
            type: 'number'
            default: .75
            minimum: 0
            maximum: 1
        highContrast:
            description: 'This will display a high contrast label,
            usually green.  It is dynamic per theme.'
            type: 'boolean'
            default: false
        useHomingBeaconEffectOnJumps:
            description: 'This will animate a short lived homing beacon upon
            jump.  It is *temporarily* not working due to architectural
            changes in Atom.'
            type: 'boolean'
            default: true
        matchPattern:
            description: 'Jumpy will create labels based on this pattern.'
            type: 'string'
            default: '([A-Z]+([0-9a-z])*)|[a-z0-9]{2,}'

    activate: (state) ->
        @jumpyView = new JumpyView state.jumpyViewState

    deactivate: ->
        @jumpyView.destroy()
        @jumpyView = null

    serialize: ->
        jumpyViewState: @jumpyView.serialize()
