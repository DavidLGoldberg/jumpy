{CompositeDisposable, Point} = require 'atom'
{View, $} = require 'space-pen'
_ = require 'underscore-plus'

lowerCharacters = "abcdefghijklmnopqrstuvwxyz".split('')
upperCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split('')

module.exports =
class JumpyView extends View
  @content: ->
    @div ''

  getLabels: ->
    return @labels.slice() if @labels?
    @labels = []
    for c1 in lowerCharacters
      for c2 in lowerCharacters
        @labels.push c1 + c2

    for c1 in upperCharacters
      for c2 in lowerCharacters
        @labels.push c1 + c2

    for c1 in lowerCharacters
      for c2 in upperCharacters
        @labels.push c1 + c2

    @labels

  initialize: (@statusBarManager) ->
    @labels = null
    @labelElement = null
    @disposables = new CompositeDisposable()
    # TODO: consider moving this into toggle for new bindings.
    @backedUpKeyBindings = atom.keymaps.getKeyBindings()

  getKey: (char) ->
    chars = if @firstChar then @firstChar + char else char

    status = ''
    @candidates = []
    @irrelevants = []
    for label, target of @label2target
      if ///^#{chars}///.test label
        @candidates.push target
      else
        @irrelevants.push target

    switch @candidates.length
      when 0
        status = 'No match!'
      when 1
        status = ''
        @jump @candidates.shift()
        @clearJumpMode()
      else
        @firstChar = char
        status = @firstChar
        _.each @irrelevants, ({element}) ->
          element.classList.add 'irrelevant'
    @statusBarManager.update status

  reset: ->
    @firstChar = null
    for {element} in @irrelevants
      element.classList.remove 'irrelevant'
    @statusBarManager.init()
    @irrelevants = []
    @candidates = []

  # Disable partial match timeout temporarily is more lighter approarch?
  replaceKeymaps: (keyBindings) ->
    atom.keymaps.keyBindings = keyBindings

  getJumpyKeyMaps: ->
    return @jumpyKeymaps if @jumpyKeymaps

    getFilteredJumpyKeys = ->
      atom.keymaps.keyBindings.filter (keymap) ->
        keymap.command.indexOf('jumpy') > -1
        #   .indexOf('jumpy') > -1 if typeof keymap.command is 'string'

    @jumpyKeymaps = getFilteredJumpyKeys()
    # Don't think I need a corresponding unobserve
    Object.observe atom.keymaps.keyBindings, =>
      @jumpyKeymaps = getFilteredJumpyKeys()

    @jumpyKeymaps

  getLabelPreference: ->
    fontSize = atom.config.get 'jumpy.fontSize'
    fontSize = .75 if isNaN(fontSize) or fontSize > 1
    fontSize = (fontSize * 100) + '%'
    highContrast = atom.config.get 'jumpy.highContrast'
    {fontSize, highContrast}

  addLabelContainer: (editorView) ->
    div = document.createElement("div")
    div.classList.add "jumpy", "jumpy-label-container"
    overlayer = editorView.shadowRoot.querySelector('content[select=".overlayer"]')
    overlayer.appendChild div
    div

  newTarget: (editorView, label, row, column) ->
    position = new Point(row, column)
    px = editorView.pixelPositionForScreenPosition position
    editor = editorView.getModel()
    scrollLeft = editor.getScrollLeft()
    scrollTop  = editor.getScrollTop()
    element    = @createLabelElement label, px, scrollLeft, scrollTop
    {label, editorView, position, px, element}

  eachVisibleEditor: (callback) ->
    labels = @getLabels()
    for editor in @getVisibleEditor()
      editorView = atom.views.getView(editor)
      editorView.classList.add 'jumpy-jump-mode'

      label2target = callback(labels, editor, editorView)

      labelContainer = @addLabelContainer editorView
      for label, {element} of label2target
        labelContainer.appendChild(element)
      @labelContainers[editor.id] = labelContainer
      _.extend(@label2target, label2target)

      # @disposables.add editor.onDidChangeScrollTop => @clearJumpMode()
      # @disposables.add editor.onDidChangeScrollLeft => @clearJumpMode()
      for event in ['blur', 'click']
        editorView.addEventListener event, @clearJumpMode.bind(@), true

  toggle: ->
    @labelContainers = {}
    @irrelevants     = []
    @candidates      = []
    @label2target    = {}
    @replaceKeymaps @getJumpyKeyMaps()
    @statusBarManager.init()

    # TODO: Can the following few lines be singleton'd up? ie. instance var?
    wordsPattern = new RegExp(atom.config.get('jumpy.matchPattern'), 'g')

    @eachVisibleEditor (labels, editor, editorView) =>
      label2target = {}
      [startRow, endRow] = editor.getVisibleRowRange()
      for row in [startRow..endRow]
        if editor.isFoldedAtScreenRow row
          label = labels.shift()
          label2target[label] = @newTarget(editorView, label, row, 0)
        else
          lineContents = editor.lineTextForScreenRow row
          while match = wordsPattern.exec(lineContents)
            label = labels.shift()
            label2target[label] = @newTarget(editorView, label, row, match.index)

      label2target

  # Return intividual labelElement
  createLabelElement: (label, px, scrollLeft, scrollTop) ->
    elem             = @getBaseLabelElement()
    elem.textContent = label
    elem.style.left  = "#{px.left - scrollLeft}px"
    elem.style.top   = "#{px.top - scrollTop}px"
    elem

  # Return base element for labelElement
  getBaseLabelElement: ->
    return @labelElement.cloneNode() if @labelElement?
    {fontSize, highContrast} = @getLabelPreference()
    klasses = ['jumpy', 'label']
    klasses.push 'high-contrast' if highContrast
    @labelElement = document.createElement "div"
    @labelElement.classList.add klasses...
    @labelElement.style.fontSize = fontSize
    @labelElement.cloneNode()

  jump: ({label, editorView, position}) ->
    editor = editorView.getModel()
    atom.workspace.paneForItem(editor).activate()

    if (editor.getSelections().length is 1) and (not editor.getLastSelection().isEmpty())
      editor.selectToScreenPosition position
    else
      editor.setCursorScreenPosition position

    {row, column} = position
    console.log "Jumpy jumped to: '#{label} at #{row}:#{column}"

  clearJumpMode: ->
    @firstChar = null
    @statusBarManager.hide()
    for editor in @getVisibleEditor()
      editorView = atom.views.getView(editor)
      @labelContainers[editor.id]?.remove()
      editorView.classList.remove 'jumpy-jump-mode'

      for event in ['blur', 'click']
        editorView.removeEventListener event, @clearJumpMode.bind(@), true

    # Restore keymaps
    @replaceKeymaps @backedUpKeyBindings
    @disposables?.dispose()
    @detach()

  destroy: ->
    console.log 'Jumpy: "destroy" called.'
    @clearJumpMode()

  getVisibleEditor: ->
    editors = atom.workspace.getPanes()
      .map    (pane)   -> pane.getActiveEditor()
      .filter (editor) -> editor?
    editors
