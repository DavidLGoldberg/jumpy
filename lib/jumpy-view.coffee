# TODO: Merge in @johngeorgewright's code for treeview
# TODO: Merge in @willdady's code for better accuracy.
# TODO: Remove space-pen?

### global atom ###
{ CompositeDisposable, Point } = require 'atom'
{ View, $ } = require 'space-pen'
_ = require 'lodash'

words = require './labelers/words'
StateMachine = require 'javascript-state-machine'
labelReducer = require './label-reducer'
{ getKeySet, drawLabel, drawBeacon } = require('./label')

class JumpyView extends View

    @content: ->
        @div ''

    initialize: ->
        @workspaceElement = atom.views.getView(atom.workspace)
        @disposables = new CompositeDisposable()
        @decorations = []
        @commands = new CompositeDisposable()

        @statusBar = document.querySelector 'status-bar'
        @statusBar?.addLeftTile
            item: $('<div id="status-bar-jumpy" class="inline-block">
                    Jumpy: <span class="status"></span>
                </div>')
            priority: -1
        @statusBarJumpy = @statusBar?.querySelector '#status-bar-jumpy'
        @statusBarJumpyStatus = @statusBarJumpy?.querySelector '.status'
        @savedInheritedDisplay = @statusBarJumpy?.style.display

        fontSize = atom.config.get 'jumpy.fontSize'
        fontSize = .75 if isNaN(fontSize) or fontSize > 1
        fontSize = (fontSize * 100) + '%'
        @settings =
            fontSize: fontSize
            highContrast: atom.config.get 'jumpy.highContrast'
            wordsPattern: new RegExp (atom.config.get 'jumpy.matchPattern'), 'g'

        @fsm = StateMachine.create {
            initial: 'off',
            events: [
                { name: 'activate', from: 'off', to: 'on' },
                { name: 'key', from: 'on', to: 'on' },
                { name: 'reset', from: 'on', to: 'on' },
                { name: 'jump', from: 'on', to: 'off' },
                { name: 'exit', from: 'on', to: 'off'  }
            ],
            callbacks:
                onactivate: (event, from, to ) =>
                    @keydownListener = (event) =>
                        # use the code property for testing if
                        # the key is relevant to Jumpy
                        # that is, that it's an alpha char.
                        # use the key character to pass the exact key
                        # that is, (upper or lower) to the state machine.
                        # if jumpy catches it...stop the event propagation.
                        {code, key, metaKey, ctrlKey, altKey} = event
                        if metaKey || ctrlKey || altKey
                            return

                        if /^Key[A-Z]{1}$/.test code
                            event.preventDefault()
                            event.stopPropagation()
                            @fsm.key key

                    @currentKeys = ''

                    # important to keep this up here and not in the observe
                    # text editor to not crash if no more keys left!
                    # this shouldn't have to be this way, but for now.
                    @keys = getKeySet()

                    @allLabels = []
                    @currentLabels = []

                    @initializeListeners(@workspaceElement)

                    @settings.wordsPattern.lastIndex = 0 # reset the RegExp for subsequent calls.
                    @disposables.add atom.workspace.observeTextEditors (editor) =>
                        editorView = atom.views.getView(editor)
                        return if $(editorView).is ':not(:visible)'

                        # 'jumpy-jump-mode is for keymaps and utilized by tests
                        editorView.classList.add 'jumpy-jump-mode',
                            'jumpy-more-specific1', 'jumpy-more-specific2'

                        # current labels for current editor in observe.
                        if !@keys.length
                            return
                        currentEditorLabels = words.getLabels editor, editorView, @keys, @settings
                        # only draw new labels
                        for label in currentEditorLabels
                            @decorations.push drawLabel label, @settings

                        @allLabels = @allLabels.concat currentEditorLabels
                        @currentLabels = _.clone @allLabels

                onkey: (event, from, to, character) =>
                    # instead... of the following, maybe do with
                    # some substate ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?
                    testKeys = @currentKeys + character
                    matched = @currentLabels.some (label) =>
                        label.keyLabel.startsWith testKeys

                    if !matched
                        @statusBarJumpy?.classList.add 'no-match'
                        @setStatus 'No Match!'
                        return
                    # ^ the above makes this func feel not single responsibility
                    # some substate ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?

                    @currentKeys = testKeys

                    for decoration in @decorations
                        element = decoration.getProperties().item
                        if !element.textContent.startsWith(@currentKeys)
                            element.classList.add 'irrelevant'

                    @setStatus character

                    @currentLabels = labelReducer @currentLabels, @currentKeys

                    if @currentLabels.length == 1 && @currentKeys.length == 2
                        if @fsm.can 'jump'
                            @fsm.jump @currentLabels[0]

                onjump: (event, from, to, location) =>
                    currentEditor = location.editor
                    editorView = atom.views.getView(currentEditor)

                    # Prevent other editors from jumping cursors as well
                    # TODO: make a test for this return if
                    return if currentEditor.id != location.editor.id

                    pane = atom.workspace.paneForItem(currentEditor)
                    pane.activate()

                    # isVisualMode is for vim-mode or vim-mode-plus:
                    isVisualMode = editorView.classList.contains 'visual-mode'
                    # isSelected is for regular selection in atom or in insert-mode in vim
                    isSelected = (currentEditor.getSelections().length == 1 &&
                        currentEditor.getSelectedText() != '')
                    position = Point(location.lineNumber, location.column)
                    if (isVisualMode || isSelected)
                        currentEditor.selectToScreenPosition position
                    else
                        currentEditor.setCursorScreenPosition position

                    if atom.config.get 'jumpy.useHomingBeaconEffectOnJumps'
                        drawBeacon currentEditor, position


                onreset: (event, from, to) =>
                    @currentKeys = ''
                    @currentLabels = _.clone @allLabels
                    for decoration in @decorations
                        element = decoration.getProperties().item
                        element.classList.remove 'irrelevant'

                # STATE CHANGES:
                onoff: (event, from, to) =>
                    if from == 'on'
                        @clearJumpMode()
                    @statusBarJumpy?.style.display = 'none'
                    @setStatus '' # Just for correctness really

                onbeforeevent: (event, from, to) =>
                    # Reset statuses:
                    @setStatus 'Jump Mode!'
                    @showStatus()
                    @statusBarJumpy?.classList.remove 'no-match'
        }

        @commands.add atom.commands.add 'atom-workspace',
            'jumpy:toggle': => @toggle()
            'jumpy:reset': =>
                if @fsm.can 'reset'
                    @fsm.reset()
            'jumpy:clear': =>
                if @fsm.can 'exit'
                    @fsm.exit()

    showStatus: -> # restore typical status bar display (inherited)
        @statusBarJumpy?.style.display = @savedInheritedDisplay

    setStatus: (status) ->
        @statusBarJumpyStatus?.innerHTML = status

    toggle: ->
        if @fsm.can 'activate'
            @fsm.activate()
        else if @fsm.can 'exit'
            @fsm.exit()

    clearJumpModeHandler: =>
        if @fsm.can 'exit'
            @fsm.exit()

    # TODO: move up into fsm
    initializeListeners: (workspace) ->
        @workspaceElement.addEventListener 'keydown', @keydownListener, true
        for e in ['blur', 'click', 'scroll']
            @workspaceElement.addEventListener e, @clearJumpModeHandler, true

    removeListeners: (workspace) ->
        @workspaceElement.removeEventListener 'keydown', @keydownListener, true
        for e in ['blur', 'click', 'scroll']
            @workspaceElement.removeEventListener e, @clearJumpModeHandler, true

    # TODO: move into fsm? change callers too
    clearJumpMode: ->
        clearAllMarkers = =>
            for decoration in @decorations
                decoration.getMarker().destroy()
            @decorations = [] # Very important for GC.
            # Verifiable in Dev Tools -> Timeline -> Nodes.

        @allLabels = []
        @removeListeners()
        @disposables.add atom.workspace.observeTextEditors (editor) =>
            editorView = atom.views.getView(editor)

            editorView.classList.remove 'jumpy-jump-mode',
                'jumpy-more-specific1', 'jumpy-more-specific2'
        clearAllMarkers()
        @disposables?.dispose()
        @detach()

    # Returns an object that can be retrieved when package is activated
    serialize: ->

    # Tear down any state and detach
    destroy: ->
        @commands?.dispose()
        @clearJumpMode()

module.exports = JumpyView
