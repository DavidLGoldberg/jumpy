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

  getChars: ->
    @firstChar + @secondChar

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

  drawLabels: (editor, position, labelContainer, labels) ->
    return unless labels.length

    label = labels.shift()
    @allPositions[label] = {editor: editor.id, position}
    editorView = atom.views.getView(editor)
    pixelPosition = editorView.pixelPositionForScreenPosition position

    {fontSize, highContrast} = @getLabelPreference()
    labelElement =
      $("<div class='jumpy label'>#{label}</div>")
        .css
          left: pixelPosition.left - editor.getScrollLeft()
          top: pixelPosition.top - editor.getScrollTop()
          fontSize: fontSize

    labelElement.addClass 'high-contrast' if highContrast
    $(labelContainer).append labelElement

  getLabelPreference: ->
    fontSize = atom.config.get 'jumpy.fontSize'
    fontSize = .75 if isNaN(fontSize) or fontSize > 1
    fontSize = (fontSize * 100) + '%'
    highContrast = atom.config.get 'jumpy.highContrast'
    {fontSize, highContrast}

  toggle: ->
      @clearJumpMode()
      @cleared = false # Set dirty for @clearJumpMode

      # TODO: Can the following few lines be singleton'd up? ie. instance var?
      wordsPattern = new RegExp (atom.config.get 'jumpy.matchPattern'), 'g'
      @replaceKeymaps @getJumpyKeyMaps()
      @statusBarManager.update 'Jump Mode!'
      @statusBarManager.show()
      @allPositions = {}
      labels = @getCharPairs()

      # @disposables.add atom.workspace.observeTextEditors (editor) =>
      for editor in @getVisibleEditor()
          editorView = atom.views.getView(editor)
          $editorView = $(editorView)
          return if $editorView.is ':not(:visible)'

          editorView.classList.add 'jumpy-jump-mode'
          overlayer = editorView.shadowRoot.querySelector('content[select=".overlayer"]')
          $(overlayer).append '<div class="jumpy jumpy-label-container"></div>'
          labelContainer = overlayer.querySelector '.jumpy-label-container'

          [startRow, endRow] = editor.getVisibleRowRange()
          for row in [startRow..endRow]
              if editor.isFoldedAtScreenRow row
                  point = new Point(row, 0)
                  @drawLabels editor, point, labelContainer, labels
              else
                  lineContents = editor.lineTextForScreenRow row
                  while ((word = wordsPattern.exec(lineContents)) != null)
                      point = new Point(row, word.index)
                      @drawLabels editor, point, labelContainer, labels

          @initializeClearEvents(editor, editorView)

  initializeClearEvents: (editor, editorView) ->
    @disposables.add editor.onDidChangeScrollTop => @clearJumpMode()
    @disposables.add editor.onDidChangeScrollLeft => @clearJumpMode()

    for e in ['blur', 'click']
      editorView.addEventListener e, @clearJumpMode.bind(@), true

  jump: ->
    inputs = @getChars()
    unless location = @allPositions[inputs]
      console.log "Jumpy canceled jump.  No location found."
      return

    return unless editor = _.detect @getVisibleEditor(), (_editor) ->
      _editor.id is location.editor

    editorView = atom.views.getView editor
    atom.workspace.paneForItem(editor).activate()

    {position} = location
    if (editor.getSelections().length is 1) and (not editor.getLastSelection().isEmpty())
      editor.selectToScreenPosition position
    else
      editor.setCursorScreenPosition position

    {row, column} = position
    console.log "Jumpy jumped to: '#{inputs} at #{row}:#{column}"

    # if atom.config.get('jumpy.useHomingBeaconEffectOnJumps')
    #   cursor = editorView.shadowRoot.querySelector '.cursors .cursor'
    #   if cursor
    #     cursor.classList.add 'beacon'
    #     setTimeout ->
    #       cursor.classList.remove 'beacon'
    #     , 150
  clearJumpMode: ->
    if @cleared
      return

    @cleared = true
    @clearChars()
    @statusBarManager.hide()
    for editor in @getVisibleEditor()
      editorView = atom.views.getView(editor)
      return if $(editorView).is ':not(:visible)'
      overlayer = editorView.shadowRoot.querySelector('content[select=".overlayer"]')
      $(overlayer).find('.jumpy').remove()
      editorView.classList.remove 'jumpy-jump-mode'
      for e in ['blur', 'click']
        editorView.removeEventListener e, @clearJumpMode.bind(@), true

    @replaceKeymaps @backedUpKeyBindings
    @disposables?.dispose()
    @detach()

  destroy: ->
    console.log 'Jumpy: "destroy" called.'
    @clearJumpMode()
