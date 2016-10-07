LabelManager = require '../label-manager'

triggerMouseEvent = (element, eventType) ->
    clickEvent = document.createEvent 'MouseEvents'
    clickEvent.initEvent eventType, true, true
    element.dispatchEvent clickEvent

class TreeViewManager extends LabelManager
    constructor: ->
        super
        @locations = []

    toggle: (keys) ->
        elements = document.querySelectorAll '.tree-view *[data-path]'
        for element in elements
            return unless keys.length
            label = @createLabel keys.shift()
            @locations.push {label, element}
            element.parentNode.insertBefore label, element

    destroy: ->
        while location = @locations.shift()
            location.label.parentNode.removeChild location.label

    drawBeacon: ({element}) ->
        beacon = @createBeacon()
        parent = element.parentNode
        parent.insertBefore beacon, element
        setTimeout ->
            parent.removeChild beacon
        , 150

    jumpTo: (firstChar, secondChar) ->
        match = "#{firstChar}#{secondChar}"
        location = @locations.find(({label}) -> label.textContent is match)
        return unless location
        @drawBeacon location
        @select location

    select: ({element}) ->
        atom.commands.dispatch(
            document.querySelector('atom-workspace'),
            'tree-view:show'
        )
        triggerMouseEvent element, 'mousedown'
        atom.commands.dispatch element, 'tree-view:open-selected-entry'

    markIrrelevant: (firstChar) ->
        @locations
            .filter(({label}) -> not label.textContent.startsWith firstChar)
            .forEach(({label}) -> label.classList.add 'irrelevant')

    unmarkIrrelevant: ->
        label.classList.remove 'irrelevant' for {label} in @locations

    findByCharacterAndPosition: (character, position) ->
        for {label} in @locations
            return label if label.textContent[position] is character
        null

module.exports = TreeViewManager
