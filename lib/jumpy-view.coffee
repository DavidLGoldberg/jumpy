# TODO: Merge in @johngeorgewright's code for treeview
# TODO: Merge in @willdady's code for better accuracy.
# TODO: Remove space-pen?

### global atom ###
LabelManagerIterator = require './label-manager-iterator'
{CompositeDisposable} = require 'atom'
{View, $} = require 'space-pen'
_ = require 'lodash'

class JumpyView extends View

    @content: ->
        @div ''

    initialize: () ->
        @labelManager = new LabelManagerIterator
        @commands = new CompositeDisposable()
        @commands.add atom.commands.add 'atom-workspace',
            'jumpy:toggle': => @toggle()
            'jumpy:reset': => @reset()
            'jumpy:clear': @clearJumpMode

        commands = LabelManagerIterator.chars.reduce(
            (commands, c) => _.set(commands, "jumpy:#{c}", => @getKey c),
            {}
        )
        @commands.add atom.commands.add 'atom-workspace', commands

        # TODO: consider moving this into toggle for new bindings.
        @backedUpKeyBindings = _.clone atom.keymaps.keyBindings

        @workspaceElement = atom.views.getView(atom.workspace)
        @statusBar = document.querySelector 'status-bar'
        @statusBar?.addLeftTile
            item: $('<div id="status-bar-jumpy" class="inline-block"></div>')
            priority: -1
        @statusBarJumpy = document.getElementById 'status-bar-jumpy'

    getKey: (character) ->
        @statusBarJumpy?.classList.remove 'no-match'

        # Assert: labelPosition will start at 0!
        labelPosition = (if not @firstChar then 0 else 1)
        if not @labelManager.isMatchOfCurrentLabels character, labelPosition
            @statusBarJumpy?.classList.add 'no-match'
            @statusBarJumpyStatus?.innerHTML = 'No match!'
            return

        if not @firstChar
            @firstChar = character
            @statusBarJumpyStatus?.innerHTML = @firstChar
            @labelManager.markIrrelevant @firstChar
        else if not @secondChar
            @secondChar = character

        if @secondChar
            @jump() # Jump first. Currently need the placement of the labels.
            _.defer @clearJumpMode

    clearKeys: ->
        @firstChar = null
        @secondChar = null

    reset: ->
        @clearKeys()
        @labelManager.unmarkIrrelevant()
        @statusBarJumpy?.classList.remove 'no-match'
        @statusBarJumpyStatus?.innerHTML = 'Jump Mode!'

    getFilteredJumpyKeys: ->
        atom.keymaps.keyBindings.filter (keymap) ->
            keymap.command.includes 'jumpy' if typeof keymap.command is 'string'

    turnOffSlowKeys: ->
        atom.keymaps.keyBindings = @getFilteredJumpyKeys()

    toggle: ->
        @clearJumpMode()

        # Set dirty for @clearJumpMode
        @cleared = false

        # 'jumpy-jump-mode is for keymaps and utilized by tests
        document.body.classList.add 'jumpy-jump-mode'

        @turnOffSlowKeys()
        @statusBarJumpy?.classList.remove 'no-match'
        @statusBarJumpy?.innerHTML =
            'Jumpy: <span class="status">Jump Mode!</span>'
        @statusBarJumpyStatus =
            document.querySelector '#status-bar-jumpy .status'

        @labelManager.toggle()
        @labelManager.initializeClearEvents @clearJumpMode

    clearJumpMode: =>
        return if @cleared
        @cleared = true
        @clearKeys()
        @statusBarJumpy?.innerHTML = ''
        document.body.classList.remove 'jumpy-jump-mode'
        atom.keymaps.keyBindings = @backedUpKeyBindings
        @labelManager.destroy()
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
