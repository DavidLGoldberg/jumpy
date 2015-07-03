_ = require 'underscore-plus'

StatusBarManager = require './status-bar-manager'
{CompositeDisposable, Disposable} = require 'atom'

LabelView = null
LabelContainerView = null

lowerCharacters = "abcdefghijklmnopqrstuvwxyz"
upperCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

Config =
  fontSize:
    description: 'The font size of jumpy labels.'
    type: 'number'
    default: .75
    minimum: 0
    maximum: 1
  highContrast:
    description: 'This will display a high contrast label, usually green.  It is dynamic per theme.'
    type: 'boolean'
    default: false
  useHomingBeaconEffectOnJumps:
    description: 'This will animate a short lived homing beacon upon jump.  It is *temporarily* not working due to architectural changes in Atom.'
    type: 'boolean'
    default: true
  matchPattern:
    description: 'Jumpy will create labels based on this pattern.'
    type: 'string'
    default: '([A-Z]+([0-9a-z])*)|[a-z0-9]{2,}'

module.exports =
  config: Config
  labels: null

  activate: ->
    @subscriptions    = new CompositeDisposable
    @statusBarManager = new StatusBarManager
    @labels = @getLabels()

    # TODO: consider moving this into toggle for new bindings.
    @backedUpKeyBindings = atom.keymaps.getKeyBindings()

    commands = {}
    for char in (lowerCharacters + upperCharacters).split('')
      do (char) =>
        commands["jumpy:#{char}"] = =>
          @getKey(char)
    @subscriptions.add atom.commands.add 'atom-workspace', commands

    @subscriptions.add atom.commands.add 'atom-workspace',
      "jumpy:toggle": => @toggle()
      "jumpy:reset":  => @reset()
      "jumpy:clear":  => @clearJumpMode()

  consumeStatusBar: (statusBar) ->
    @statusBarManager.initialize(statusBar)
    @statusBarManager.attach()
    @subscriptions.add new Disposable =>
      @statusBarManager.detach()

  deactivate: ->
    # console.log 'Jumpy: "destroy" called.'
    @clearJumpMode()
    @subscriptions.dispose()

  # Toggle
  # -------------------------
  toggle: ->
    LabelView ?= require './label-view'
    LabelContainerView ?= require './label-container-view'

    @containers   = []
    @unMatched    = []
    @matched      = []
    @label2target = {}
    @statusBarManager.init()

    @replaceKeymaps @getJumpyKeyMaps()
    # TODO: Can the following few lines be singleton'd up? ie. instance var?
    pattern = new RegExp(atom.config.get('jumpy.matchPattern'), 'g')

    @displayLabel pattern, @labels.slice(), @getLabelPreference()

  displayLabel: (pattern, labels, labelPreference) ->
    for editor in @getVisibleEditor()
      # pattern = editor.getLastCursor().wordRegExp()
      @setJumpMode editor
      container = new LabelContainerView()
      container.initialize(editor)

      editorView     = atom.views.getView(editor)
      label2point    = @getLabel2Point labels, @collectPoints(editor, pattern)
      label2target   = @getLabel2Target label2point, {labelPreference, editorView}
      container.appendChildren _.values(label2target)
      @containers.push container
      _.extend @label2target, label2target

  collectPoints: (editor, pattern) ->
    [startRow, endRow] = editor.getVisibleRowRange()
    scanStart = [startRow, Infinity]
    scanEnd   = [endRow, Infinity]
    scanStart = [5, Infinity]
    scanEnd   = [30, Infinity]
    scanRange = [scanStart, scanEnd]
    points = []
    editor.scanInBufferRange pattern, scanRange, ({range, stop}) =>
      points.push range.start
    points

  getLabel2Point: (labels, points) ->
    label2point = {}
    for point in points
      break unless labels.length
      label2point[labels.shift()] = point
    label2point

  # [NOTE]
  # _.mapObject is different between underscore.js and underscore-plus
  # This is underscore-plus.
  getLabel2Target: (label2point, options) ->
    _.mapObject label2point, (label, position) ->
      _.extend options, {label, position}
      element = new LabelView()
      element.initialize options
      [label, element]

  # GetKey
  # -------------------------
  getKey: (char) ->
    chars = if @firstChar then @firstChar + char else char
    labelPattern = ///^#{chars}///
    [@matched, @unMatched] = @partitionTarget @label2target, (label) ->
      labelPattern.test label
    status = ''
    switch @matched.length
      when 0
        status = 'No match!'
      when 1
        @matched.shift().jump()
        @clearJumpMode()
      else
        @firstChar = char
        status = @firstChar
        for labelElement in @unMatched
          labelElement.unMatch()
    @statusBarManager.update status

  partitionTarget: (label2target, callback) ->
    matched = []
    unMatched = []
    for label, target of label2target
      if callback(label)
        matched.push target
      else
        unMatched.push target
    [matched, unMatched]

  reset: ->
    @firstChar = null
    for container in @containers
      container.reset()

  setJumpMode: (editor) ->
    editorView = atom.views.getView(editor)
    editorView.classList.add 'jumpy-jump-mode'
    for event in ['blur', 'click']
      editorView.addEventListener event, @clearJumpModeCallback(), true

  unSetJumpMode: (editor) ->
    editorView = atom.views.getView editor
    editorView.classList.remove 'jumpy-jump-mode'
    for event in ['blur', 'click']
      editorView.removeEventListener event, @clearJumpModeCallback(), true

  clearJumpModeCallback: ->
    @_clearJumpModeCallback ?= @clearJumpMode.bind(this)

  clearJumpMode: ->
    @firstChar = null
    @statusBarManager.hide()
    element.remove() for label, element of @label2target
    @label2target = null

    for container in @containers
      container.destroy()
    @containers = []
    for editor in @getVisibleEditor()
      @unSetJumpMode(editor)

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

  # Utility
  # -------------------------
  getConfig: (param) ->
    atom.config.get "jumpy.#{param}"

  getLabelPreference: ->
    fontSize = @getConfig 'fontSize'
    fontSize = .75 if isNaN(fontSize) or fontSize > 1
    fontSize = (fontSize * 100) + '%'
    highContrast = @getConfig 'highContrast'
    {fontSize, highContrast}

  getVisibleEditor: ->
    editors = atom.workspace.getPanes()
      .map    (pane)   -> pane.getActiveEditor()
      .filter (editor) -> editor?
    editors

  getLabels: ->
    labels = []
    for c1 in lowerCharacters
      for c2 in lowerCharacters
        labels.push c1 + c2

    for c1 in upperCharacters
      for c2 in lowerCharacters
        labels.push c1 + c2

    for c1 in lowerCharacters
      for c2 in upperCharacters
        labels.push c1 + c2
    labels
