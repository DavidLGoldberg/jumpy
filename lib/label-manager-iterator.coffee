{Point, Range} = require 'atom'
fs = require 'fs'
pathHelper = require 'path'
_ = require 'lodash'

LABEL_MANAGER_PATH = pathHelper.join __dirname, 'label-managers'
labelManagers = fs
    .readdirSync(LABEL_MANAGER_PATH)
    .map((file) -> require(pathHelper.join LABEL_MANAGER_PATH, file))

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

class LabelManagerIterator
    @keys: keys
    @chars: lowerCharacters.concat upperCharacters

    constructor: (disposables, commands) ->
        @clickableLabels = []
        @labelManagers = labelManagers.map((Manager) -> new Manager disposables)
        atom.config.observe 'jumpy.fontSize', @setFontSize
        atom.config.observe 'jumpy.matchPattern', @setWordsPattern
        atom.config.observe 'jumpy.highContrast', @setHighContrast

    setHighContrast: (value) =>
        manager.highContrast = value for manager in @labelManagers

    setWordsPattern: (value) =>
        value = new RegExp value, 'g'
        manager.matchPattern = value for manager in @labelManagers

    setFontSize: (value) =>
        value = .75 if isNaN(value) or value > 1
        value = (value * 100) + '%'
        manager.fontSize = value for manager in @labelManagers

    toggle: ->
        nextKeys = _.clone keys
        manager.toggle nextKeys for manager in @labelManagers

    jumpTo: (firstChar, secondChar) ->
        manager.jumpTo firstChar, secondChar for manager in @labelManagers

    destroy: ->
        manager.destroy() for manager in @labelManagers

    markIrrelevant: (firstChar) ->
        manager.markIrrelevant firstChar for manager in @labelManagers

    unmarkIrrelevant: ->
        manager.unmarkIrrelevant() for manager in @labelManagers

    isMatchOfCurrentLabels: (character, position) ->
        found = null
        for manager in @labelManagers
            found = manager.isMatchOfCurrentLabels character, position
            break if found
        found

module.exports = LabelManagerIterator
