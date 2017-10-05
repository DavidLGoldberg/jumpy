{ Point, Range } = require 'atom'
_ = require 'lodash'

lowerCharacters =
    (String.fromCharCode(a) for a in ['a'.charCodeAt()..'z'.charCodeAt()])
upperCharacters =
    (String.fromCharCode(a) for a in ['A'.charCodeAt()..'Z'.charCodeAt()])

keys = []

# A little ugly.
# I used itertools.permutation in python.
# Couldn't find a good one in npm.  Don't worry this takes < 1ms once.
for c1 in lowerCharacters
    for c2 in lowerCharacters
        keys.push c1 + c2
for c1 in upperCharacters
    for c2 in lowerCharacters
        keys.push c1 + c2
for c1 in lowerCharacters
    for c2 in upperCharacters
        keys.push c1 + c2

getCharacterSets = ->
    [ lowerCharacters, upperCharacters ]

getKeySet = ->
    _.clone keys

drawLabels = (editor, setPositions, lineNumber, column, settings) ->
    return unless settings.keys.length

    keyLabel = settings.keys.shift()
    position = {row: lineNumber, column: column}
    # creates a reference:
    setPositions keyLabel,
        editor: editor.id
        position: position

    marker = editor.markScreenRange new Range(
        new Point(lineNumber, column),
        new Point(lineNumber, column)),
        invalidate: 'touch'

    labelElement = document.createElement('div')
    labelElement.textContent = keyLabel
    labelElement.style.fontSize = settings.fontSize
    labelElement.classList.add 'jumpy-label'

    if settings.highContrast
        labelElement.classList.add 'high-contrast'

    decoration = editor.decorateMarker marker,
        type: 'overlay'
        item: labelElement
        position: 'head'
    return decoration

drawBeacon = (editor, location) ->
    range = Range location.position, location.position
    marker = editor.markScreenRange range, invalidate: 'never'
    beacon = document.createElement 'span'
    beacon.classList.add 'beacon'
    editor.decorateMarker marker,
        item: beacon,
        type: 'overlay'
    setTimeout ->
        marker.destroy()
    , 150

module.exports = { getCharacterSets, getKeySet, drawLabels, drawBeacon }
