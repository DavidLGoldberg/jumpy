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
    @jumpTarget = new Map()
    @labelElement = null
    @disposables = new CompositeDisposable()
    # TODO: consider moving this into toggle for new bindings.
    @backedUpKeyBindings = atom.keymaps.getKeyBindings()
    @workspaceElement = atom.views.getView(atom.workspace)

  getKey: (char) ->
    chars = if @firstChar then @firstChar + char else char
    labels = _.keys @label2Element
    [candidates, irrelevants] = _.partition labels, (label) ->
      ///^#{chars}///.test label

    if candidates.length is 0
      @statusBarManager.noMatch()
    else if candidates.length is 1
      @jump chars
      @clearJumpMode()
    else
      for irrelevant in irrelevants
        elem = @label2Element[irrelevant]
        elem.classList.add 'irrelevant'
        @irrelevants.push elem
        # @label2Element[irrelevant].classList.add 'irrelevant'
      @statusBarManager.update @firstChar
      @firstChar = char

  clearChars: ->
    @firstChar = null

  getVisibleEditor: ->
    editors = atom.workspace.getPanes()
      .map    (pane)   -> pane.getActiveEditor()
      .filter (editor) -> editor?
    editors

  reset: ->
    @clearChars()
    @irrelevants.forEach (elem) ->
      elem.classList.remove 'irrelevant'
    @statusBarManager.update 'Jump Mode!'
    @irrelevants = []

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
    @irrelevants = []

    # TODO: Can the following few lines be singleton'd up? ie. instance var?
    wordsPattern = new RegExp (atom.config.get 'jumpy.matchPattern'), 'g'
    @replaceKeymaps @getJumpyKeyMaps()

    @statusBarManager.update 'Jump Mode!'
    @statusBarManager.show()
    @jumpTarget.clear()
    @label2Element = {}

    labels = @getLabels()
    for editor in @getVisibleEditor()
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

      editorView = atom.views.getView(editor)
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
      elem = @createLabelElement label, px, scrollLeft, scrollTop
      @label2Element[label] = elem
      container.appendChild(elem)

  getTarget: (label) ->
    iterator = @jumpTarget.entries()
    while value = iterator.next().value
      [editor, label2point] = value
      if position = label2point[label]
        return {editor, position}
    return null

  jump: (label) ->
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
