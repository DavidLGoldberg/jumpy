{Point} = require 'atom'
_ = require 'underscore-plus'

lowerCharacters = "abcdefghijklmnopqrstuvwxyz".split('')
upperCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split('')

# [FIXME] This class is not simple View, its essencially controller.
module.exports =
class JumpyView
  constructor: (@statusBarManager) ->
    @labels = null
    @baseElement = null
    # TODO: consider moving this into toggle for new bindings.
    @backedUpKeyBindings = atom.keymaps.getKeyBindings()

  destroy: ->
    # console.log 'Jumpy: "destroy" called.'
    @clearJumpMode()

  # Toggle
  # -------------------------
  toggle: ->
    @labelContainers = {}
    @irrelevants     = []
    @candidates      = []
    @label2target    = {}
    @replaceKeymaps @getJumpyKeyMaps()
    @statusBarManager.init()

    # TODO: Can the following few lines be singleton'd up? ie. instance var?
    wordsPattern = new RegExp(atom.config.get('jumpy.matchPattern'), 'g')

    @prepareTarget (labels, editor, editorView) =>
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

  prepareTarget: (callback) ->
    labels = @getLabels()
    for editor in @getVisibleEditor()
      editorView = atom.views.getView(editor)
      editorView.classList.add 'jumpy-jump-mode'

      label2target = callback(labels, editor, editorView)
      # console.log label2target

      labelContainer = @addLabelContainer editorView
      for label, {element} of label2target
        labelContainer.appendChild(element)
      @labelContainers[editor.id] = labelContainer
      _.extend(@label2target, label2target)

      for event in ['blur', 'click']
        editorView.addEventListener event, @clearJumpMode.bind(@), true

  # GetKey
  # -------------------------
  getKey: (char) ->
    chars = if @firstChar then @firstChar + char else char
    status = ''
    labelPattern = ///^#{chars}///
    [@candidates, @irrelevants] = @classifyTarget @label2target, (label) ->
      labelPattern.test label

    switch @candidates.length
      when 0
        status = 'No match!'
      when 1
        @jump @candidates.shift()
        @clearJumpMode()
      else
        @firstChar = char
        status = @firstChar
        for {element} in @irrelevants
          element.classList.add 'irrelevant'

    @statusBarManager.update status

  classifyTarget: (label2target, callback) ->
    candidates = []
    irrelevants = []
    for label, target of label2target
      if callback(label)
        candidates.push target
      else
        irrelevants.push target
    [candidates, irrelevants]

  reset: ->
    @firstChar = null
    for {element} in @irrelevants
      element.classList.remove 'irrelevant'
    @statusBarManager.init()
    @irrelevants = []
    @candidates = []

  # Jump
  # -------------------------
  jump: ({label, editorView, position}) ->
    editor = editorView.getModel()
    atom.workspace.paneForItem(editor).activate()

    if (editor.getSelections().length is 1) and (not editor.getLastSelection().isEmpty())
      editor.selectToScreenPosition position
    else
      editor.setCursorScreenPosition position

    {row, column} = position
    # console.log "Jumpy jumped to: '#{label} at #{row}:#{column}"

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

  # Keymaps
  # -------------------------
  replaceKeymaps: (keyBindings) ->
    atom.keymaps.keyBindings = keyBindings

  getJumpyKeyMaps: ->
    return @jumpyKeymaps if @jumpyKeymaps

    getFilteredJumpyKeys = ->
      atom.keymaps.keyBindings.filter (keymap) ->
        keymap.command.indexOf('jumpy') > -1 if typeof keymap.command is 'string'

    @jumpyKeymaps = getFilteredJumpyKeys()
    # Don't think I need a corresponding unobserve
    Object.observe atom.keymaps.keyBindings, =>
      @jumpyKeymaps = getFilteredJumpyKeys()

    @jumpyKeymaps

  # Target / Label elment
  # -------------------------
  getLabelPreference: ->
    fontSize = atom.config.get 'jumpy.fontSize'
    fontSize = .75 if isNaN(fontSize) or fontSize > 1
    fontSize = (fontSize * 100) + '%'
    highContrast = atom.config.get 'jumpy.highContrast'
    {fontSize, highContrast}

  addLabelContainer: (editorView) ->
    container = document.createElement("div")
    container.classList.add "jumpy", "jumpy-label-container"
    overlayer = editorView.shadowRoot.querySelector('content[select=".overlayer"]')
    overlayer.appendChild container
    container

  newTarget: (editorView, label, row, column) ->
    position = new Point(row, column)
    px = editorView.pixelPositionForScreenPosition position
    editor = editorView.getModel()
    scrollLeft = editor.getScrollLeft()
    scrollTop  = editor.getScrollTop()
    element    = @createLabelElement label, px, scrollLeft, scrollTop
    {label, editorView, position, px, element}

  # Return intividual labelElement
  createLabelElement: (label, px, scrollLeft, scrollTop) ->
    elem             = @getBaseElement()
    elem.textContent = label
    elem.style.left  = "#{px.left - scrollLeft}px"
    elem.style.top   = "#{px.top - scrollTop}px"
    elem

  # Return base element for labelElement
  getBaseElement: ->
    return @baseElement.cloneNode() if @baseElement?
    {fontSize, highContrast} = @getLabelPreference()
    klasses = ['jumpy', 'label']
    klasses.push 'high-contrast' if highContrast
    @baseElement = document.createElement "div"
    @baseElement.classList.add klasses...
    @baseElement.style.fontSize = fontSize
    @baseElement.cloneNode()

  # Utility
  # -------------------------
  getVisibleEditor: ->
    editors = atom.workspace.getPanes()
      .map    (pane)   -> pane.getActiveEditor()
      .filter (editor) -> editor?
    editors

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

    @labels.slice()
