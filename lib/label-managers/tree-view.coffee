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
        for element in elements when keys.length
            label = @createLabel keys.shift()
            @locations.push {label, element}
            element.parentNode.insertBefore label, element

    destroy: ->
        location.label.remove() while location = @locations.shift()

    drawBeacon: ({element}) ->
        beacon = @createBeacon()
        element.parentNode.insertBefore beacon, element
        setTimeout beacon.remove.bind(beacon), 2000

    jumpTo: (firstChar, secondChar) ->
        match = "#{firstChar}#{secondChar}"
        location = @locations.find ({label}) -> label.textContent is match
        return unless location
        @drawBeacon location
        @select location

    select: ({element}) ->
        atom.commands.dispatch element, 'tree-view:show'
        triggerMouseEvent element, 'mousedown'
        atom.commands.dispatch element, 'tree-view:open-selected-entry'

    markIrrelevant: (firstChar) ->
        @locations
            .filter(({label}) -> not label.textContent.startsWith firstChar)
            .forEach(({label}) -> label.classList.add 'irrelevant')

    unmarkIrrelevant: ->
        label.classList.remove 'irrelevant' for {label} in @locations

    isMatchOfCurrentLabels: (character, position) ->
        @locations.find ({label}) -> label.textContent[position] is character

module.exports = TreeViewManager
