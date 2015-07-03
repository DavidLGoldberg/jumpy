{Point} = require 'atom'
_ = require 'underscore-plus'

LabelView = null
LabelContainerView = null

# [FIXME] This class is not simple View, its essencially controller.
# Maybe all code should be moved to main.coffee?
module.exports =
class JumpyView
  constructor: (@statusBarManager) ->
    @labels = null
    # TODO: consider moving this into toggle for new bindings.
    @backedUpKeyBindings = atom.keymaps.getKeyBindings()

  destroy: ->
    # console.log 'Jumpy: "destroy" called.'
    @clearJumpMode()

  # Toggle
  # -------------------------
  toggle: ->
    LabelView ?= require './label-view'
    LabelContainerView ?= require './label-container-view'

    @labelContainers = []
    @unMatched       = []
    @matched         = []
    @label2target    = {}
    @statusBarManager.init()

    @replaceKeymaps @getJumpyKeyMaps()

    # TODO: Can the following few lines be singleton'd up? ie. instance var?
    pattern = new RegExp(atom.config.get('jumpy.matchPattern'), 'g')

    labelPreference = @getLabelPreference()
    labels =  @getLabels()
    for editor in @getVisibleEditor()
      # pattern = editor.getLastCursor().wordRegExp()

      editorView = atom.views.getView(editor)
      @setJumpMode(editor)

      points         = @collectPoints(editor, pattern)
      label2point    = @getLabel2Point labels, points
      label2target   = @getLabel2Target label2point, {labelPreference, editorView}
      labelContainer = new LabelContainerView()
      labelContainer.initialize(editor)
      labelContainer.appendChildren _.values(label2target)
      @labelContainers.push labelContainer
      _.extend(@label2target, label2target)

  collectPoints: (editor, pattern) ->
    [startRow, endRow] = editor.getVisibleRowRange()
    scanStart = [startRow, Infinity]
    scanEnd   = [endRow, Infinity]
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
    for container in @labelContainers
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

    for container in @labelContainers
      container.destroy()
    @labelContainers = []
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
  getLabelPreference: ->
    fontSize = atom.config.get 'jumpy.fontSize'
    fontSize = .75 if isNaN(fontSize) or fontSize > 1
    fontSize = (fontSize * 100) + '%'
    highContrast = atom.config.get 'jumpy.highContrast'
    {fontSize, highContrast}

  getVisibleEditor: ->
    editors = atom.workspace.getPanes()
      .map    (pane)   -> pane.getActiveEditor()
      .filter (editor) -> editor?
    editors

  getEditor: ->
    atom.workspace.getActiveTextEditor()

  getLabels: ->
    return @labels.slice() if @labels?

    lowerCharacters = "abcdefghijklmnopqrstuvwxyz".split('')
    upperCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split('')
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
