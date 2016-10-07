# TODO: Merge in @willdady's code for better accuracy.
# TODO: Remove space-pen?

### global atom ###
LabelManagerIterator = require './label-manager-iterator'
{CompositeDisposable, Point, Range} = require 'atom'
{View, $} = require 'space-pen'
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

class JumpyView extends View

    @content: ->
        @div ''

    initialize: () ->
        @disposables = new CompositeDisposable()
        @commands = new CompositeDisposable()
        @labelManager = new LabelManagerIterator @disposables

        @commands.add atom.commands.add 'atom-workspace',
            'jumpy:toggle': => @toggle()
            'jumpy:reset': => @reset()
            'jumpy:clear': => @clearJumpMode()

        commands = {}
        for characterSet in [lowerCharacters, upperCharacters]
            for c in characterSet
                do (c) => commands['jumpy:' + c] = => @getKey(c)
        @commands.add atom.commands.add 'atom-workspace', commands

        # TODO: consider moving this into toggle for new bindings.
        @backedUpKeyBindings = _.clone atom.keymaps.keyBindings

        @workspaceElement = atom.views.getView(atom.workspace)
        @statusBar = document.querySelector 'status-bar'
        @statusBar?.addLeftTile
            item: $('<div id="status-bar-jumpy" class="inline-block"></div>')
            priority: -1
        @statusBarJumpy = document.getElementById 'status-bar-jumpy'

        @initKeyFilters()

    getKey: (character) ->
        @statusBarJumpy?.classList.remove 'no-match'

        isMatchOfCurrentLabels = (character, labelPosition) =>
            found = false
            @disposables.add atom.workspace.observeTextEditors (editor) =>
                editorView = atom.views.getView(editor)
                return if $(editorView).is ':not(:visible)'
                found = @labelManager.findByCharacterAndPosition(
                    character, labelPosition)
                return false if found
            return found

        # Assert: labelPosition will start at 0!
        labelPosition = (if not @firstChar then 0 else 1)
        if !isMatchOfCurrentLabels character, labelPosition
            @statusBarJumpy?.classList.add 'no-match'
            @statusBarJumpyStatus?.innerHTML = 'No match!'
            return

        if not @firstChar
            @firstChar = character
            @statusBarJumpyStatus?.innerHTML = @firstChar
            # TODO: Refactor this so not 2 calls to observeTextEditors
            @disposables.add atom.workspace.observeTextEditors (editor) =>
                editorView = atom.views.getView(editor)
                return if $(editorView).is ':not(:visible)'
                @labelManager.markIrrelevant @firstChar
        else if not @secondChar
            @secondChar = character

        if @secondChar
            @jump() # Jump first.  Currently need the placement of the labels.
            @clearJumpMode()

    clearKeys: ->
        @firstChar = null
        @secondChar = null

    reset: ->
        @clearKeys()
        @labelManager.unmarkIrrelevant()
        @statusBarJumpy?.classList.remove 'no-match'
        @statusBarJumpyStatus?.innerHTML = 'Jump Mode!'

    initKeyFilters: ->
        @filteredJumpyKeys = @getFilteredJumpyKeys()
        Object.observe atom.keymaps.keyBindings, ->
            @filteredJumpyKeys = @getFilteredJumpyKeys()
        # Don't think I need a corresponding unobserve

    getFilteredJumpyKeys: ->
        atom.keymaps.keyBindings.filter (keymap) ->
            keymap.command
                .indexOf('jumpy') > -1 if typeof keymap.command is 'string'

    turnOffSlowKeys: ->
        atom.keymaps.keyBindings = @filteredJumpyKeys

    toggle: ->
        @clearJumpMode()

        # Set dirty for @clearJumpMode
        @cleared = false

        # 'jumpy-jump-mode is for keymaps and utilized by tests
        document.body.classList.add 'jumpy-jump-mode'

        # TODO: Can the following few lines be singleton'd up? ie. instance var?
        @turnOffSlowKeys()
        @statusBarJumpy?.classList.remove 'no-match'
        @statusBarJumpy?.innerHTML =
            'Jumpy: <span class="status">Jump Mode!</span>'
        @statusBarJumpyStatus =
            document.querySelector '#status-bar-jumpy .status'

        @labelManager.toggle()

        @disposables.add atom.workspace.observeTextEditors (editor) =>
            editorView = atom.views.getView(editor)
            @initializeClearEvents(editorView)

    clearJumpModeHandler: =>
        @clearJumpMode()

    initializeClearEvents: (editorView) ->
        @disposables.add editorView.onDidChangeScrollTop =>
            @clearJumpModeHandler()
        @disposables.add editorView.onDidChangeScrollLeft =>
            @clearJumpModeHandler()

        for e in ['blur', 'click']
            editorView.addEventListener e, @clearJumpModeHandler, true

    clearJumpMode: ->
        if @cleared
            return

        @cleared = true
        @clearKeys()
        @statusBarJumpy?.innerHTML = ''
        @disposables.add atom.workspace.observeTextEditors (editor) =>
            editorView = atom.views.getView(editor)

            document.body.classList.remove 'jumpy-jump-mode'
            for e in ['blur', 'click']
                editorView.removeEventListener e, @clearJumpModeHandler, true
        atom.keymaps.keyBindings = @backedUpKeyBindings
        @labelManager.destroy()
        @disposables?.dispose()
        @detach()

    jump: ->
        @labelManager.jumpTo @firstChar, @secondChar

    # Returns an object that can be retrieved when package is activated
    serialize: ->

    # Tear down any state and detach
    destroy: ->
        @commands?.dispose()
        @clearJumpMode()

module.exports = JumpyView
