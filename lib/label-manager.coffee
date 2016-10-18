{CompositeDisposable} = require 'atom'

abstractMethod = (cls, methodName) ->
    cls::[methodName] = ->
        throw new Error(
            "The abstract method #{cls.name}::#{methodName} needs to exist")

class LabelManager
    constructor: ->
        @disposables = new CompositeDisposable

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

    destroy: ->
        @disposables.dispose()
        @disposables = new CompositeDisposable

    abstractMethod @, 'toggle'

    abstractMethod @, 'markIrrelevant'

    abstractMethod @, 'unmarkIrrelevant'

    abstractMethod @, 'isMatchOfCurrentLabels'

    abstractMethod @, 'jumpTo'

    abstractMethod @, 'initializeClearEvents'

module.exports = LabelManager
