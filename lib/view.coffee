"use 6to5"
# Shortly after 2.0 release action items:
# (need to rush release a little bit because
# the default shadow dom option has been enabled by atom!)
# FIXME: Beacon code (currently broken in shadow).  This will probably return
# in the form of a decoration with a "flash", not sure yet.
# TODO: Merge in @willdady's code for better accuracy.
# TODO: Investigate using markers, else my own custom elements.
# TODO: Remove space-pen? Probably alongside markers todo above.

{CompositeDisposable, Point} = require 'atom'
{View, $} = require 'space-pen'
_ = require 'lodash'

lowerCharacters = "abcdefghijklmnopqrstuvwxyz".split('')
upperCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split('')

module.exports =
class JumpyView extends View
  @content: ->
    @div ''

  constructor: (@statusBarManager) ->
    super()

  getCharPairs: ->
    return @charPairs.slice() if @charPairs?
    @charPairs = []
    for c1 in lowerCharacters
      for c2 in lowerCharacters
        @charPairs.push c1 + c2

    for c1 in upperCharacters
      for c2 in lowerCharacters
        @charPairs.push c1 + c2

    for c1 in lowerCharacters
      for c2 in upperCharacters
        @charPairs.push c1 + c2

    @charPairs

  initialize: ->
    @charPairs = null
    @jumpTarget = new Map()
    @labelElement = null
    @disposables = new CompositeDisposable()
    # TODO: consider moving this into toggle for new bindings.
    @backedUpKeyBindings = atom.keymaps.getKeyBindings()
    @workspaceElement = atom.views.getView(atom.workspace)
    # @initKeyFilters()

  getKey: (character) ->
      @statusBarManager.update()

      isMatchOfCurrentLabels = (character, labelPosition) =>
          found = false
          @disposables.add atom.workspace.observeTextEditors (editor) ->
              editorView = atom.views.getView(editor)
              return if $(editorView).is ':not(:visible)'

              overlayer = editorView.shadowRoot.querySelector('content[select=".overlayer"]')
              $(overlayer).find('.label:not(.irrelevant)').each (i, label) ->
                  if label.innerHTML[labelPosition] == character
                      found = true
                      return false
          return found

      # Assert: labelPosition will start at 0!
      labelPosition = (if not @firstChar then 0 else 1)
      if !isMatchOfCurrentLabels character, labelPosition
          @statusBarManager.noMatch()
          return

      if not @firstChar
          @firstChar = character
          @statusBarManager.update @firstChar
          # TODO: Refactor this so not 2 calls to observeTextEditors
          @disposables.add atom.workspace.observeTextEditors (editor) =>
              editorView = atom.views.getView(editor)
              return if $(editorView).is ':not(:visible)'

              overlayer = editorView.shadowRoot.querySelector('content[select=".overlayer"]')
              for label in overlayer.querySelectorAll '.jumpy.label'
                  if label.innerHTML.indexOf(@firstChar) != 0
                      label.classList.add 'irrelevant'
      else if not @secondChar
          @secondChar = character

      if @secondChar
          @jump() # Jump first.  Currently need the placement of the labels.
          @clearJumpMode()

  clearChars: ->
    @firstChar = null
    @secondChar = null

  getVisibleEditor: ->
    editors = atom.workspace.getPanes()
      .map    (pane)   -> pane.getActiveEditor()
      .filter (editor) -> editor?
    editors

  reset: ->
    @clearChars()
    for editor in @getVisibleEditor()
      editorView = atom.views.getView(editor)
      overlayer = editorView.shadowRoot.querySelector('content[select=".overlayer"]')
      $(overlayer).find '.irrelevant'
        .removeClass 'irrelevant'

    @statusBarManager.update 'Jump Mode!'

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
    editorView.classList.add 'jumpy-jump-mode'
    div = document.createElement("div")
    div.classList.add "jumpy", "jumpy-label-container"
    overlayer = editorView.shadowRoot.querySelector('content[select=".overlayer"]')
    overlayer.appendChild div
    div

  removeLabelContainer: (editorView) ->
    overlayer = editorView.shadowRoot.querySelector('content[select=".overlayer"]')
    $(overlayer).find('.jumpy').remove()
    editorView.classList.remove 'jumpy-jump-mode'

  toggle: ->
    @clearJumpMode()
    @cleared = false # Set dirty for @clearJumpMode

    # TODO: Can the following few lines be singleton'd up? ie. instance var?
    wordsPattern = new RegExp (atom.config.get 'jumpy.matchPattern'), 'g'
    @replaceKeymaps @getJumpyKeyMaps()

    @statusBarManager.update 'Jump Mode!'
    @statusBarManager.show()
    @jumpTarget.clear()

    labels = @getCharPairs()
    for editor in @getVisibleEditor()
      # wordRegExp = editor.getLastCursor().wordRegExp()
      editorView = atom.views.getView(editor)
      label2point = {}

      [startRow, endRow] = editor.getVisibleRowRange()
      for row in [startRow..endRow]
        if editor.isFoldedAtScreenRow row
          label2point[labels.shift()] = new Point(row, 0)
        else
          lineContents = editor.lineTextForScreenRow row
          while match = wordsPattern.exec(lineContents)
            label2point[labels.shift()] = new Point(row, match.index)

      @jumpTarget.set editor, label2point
      @renderLabels editor, label2point
      # @disposables.add editor.onDidChangeScrollTop => @clearJumpMode()
      # @disposables.add editor.onDidChangeScrollLeft => @clearJumpMode()

      for e in ['blur', 'click']
        editorView.addEventListener e, @clearJumpMode.bind(@), true

  # Return base element for labelElement
  getLabelElement: ->
    return @labelElement.cloneNode() if @labelElement?

    {fontSize, highContrast} = @getLabelPreference()
    elem = document.createElement "div"
    elem.classList.add "jumpy", "label"
    elem.classList.add "high-contrast" if highContrast
    elem.style.fontSize = fontSize
    @labelElement = elem

    @labelElement.cloneNode()

  # Return intividual labelElement
  createLabelElement: (label, px, scrollLeft, scrollTop) ->
    elem             = @getLabelElement()
    elem.textContent = label
    elem.style.left  = "#{px.left - scrollLeft}px"
    elem.style.top   = "#{px.top - scrollTop}px"
    elem

  renderLabels: (editor, label2point, preference) ->
    editorView = atom.views.getView(editor)
    scrollLeft = editor.getScrollLeft()
    scrollTop  = editor.getScrollTop()
    container = @addLabelContainer editorView

    for label, position of label2point
      px = editorView.pixelPositionForScreenPosition position
      container.appendChild(@createLabelElement label, px, scrollLeft, scrollTop)

  getTarget: (label) ->
    iterator = @jumpTarget.entries()
    while value = iterator.next().value
      [editor, label2point] = value
      if position = label2point[label]
        return {editor, position}
    return null

  jump: ->
    label = @firstChar + @secondChar
    unless target = @getTarget label
      console.log "Jumpy canceled jump.  No target found."
      return

    {editor, position} = target
    editorView = atom.views.getView editor
    atom.workspace.paneForItem(editor).activate()

    if (editor.getSelections().length is 1) and (not editor.getLastSelection().isEmpty())
      editor.selectToScreenPosition position
    else
      editor.setCursorScreenPosition position

    {row, column} = position
    console.log "Jumpy jumped to: '#{label} at #{row}:#{column}"

  clearJumpMode: ->
    return if @cleared
    @cleared = true

    @clearChars()
    @statusBarManager.hide()
    for editor in @getVisibleEditor()
      editorView = atom.views.getView(editor)
      @removeLabelContainer editorView
      for e in ['blur', 'click']
        editorView.removeEventListener e, @clearJumpMode.bind(@), true

    # Restore keymaps
    @replaceKeymaps @backedUpKeyBindings
    @disposables?.dispose()
    @detach()

  destroy: ->
    console.log 'Jumpy: "destroy" called.'
    @clearJumpMode()
