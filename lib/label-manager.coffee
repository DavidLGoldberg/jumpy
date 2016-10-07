abstractMethod = (name) ->->
    throw new Error "The abstract method #{name} needs to be created"

class LabelManager
    constructor: (@disposables) ->

    createLabel: (text) ->
        labelElement = document.createElement('span')
        labelElement.textContent = text
        labelElement.style.fontSize = @fontSize
        labelElement.classList.add 'jumpy-label'
        labelElement.classList.add 'high-contrast' if @highContrast
        labelElement

    createBeacon: ->
        beacon = document.createElement 'span'
        beacon.classList.add 'beacon'
        beacon

    toggle: abstractMethod 'toggle'

    destroy: abstractMethod 'destroy'

    markIrrelevant: abstractMethod 'markIrrelevant'

    unmarkIrrelevant: abstractMethod 'unmarkIrrelevant'

    findByCharacterAndPosition: abstractMethod 'findByCharacterAndPosition'

    jumpTo: abstractMethod 'jumpTo'

module.exports = LabelManager
