{Point} = require 'atom'
_ = require 'underscore-plus'
LabelView = null
LabelContainerView = null

# [FIXME] This class is not simple View, its essencially controller.
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
    @labelContainers = []
    @unMatched       = []
    @matched         = []
    @label2target    = {}
    @statusBarManager.init()
    LabelContainerView ?= require './label-container-view'

    @replaceKeymaps @getJumpyKeyMaps()

    # TODO: Can the following few lines be singleton'd up? ie. instance var?
    pattern = new RegExp(atom.config.get('jumpy.matchPattern'), 'g')

    labelPreference = @getLabelPreference()
    labels =  @getLabels()
    for editor in @getVisibleEditor()
      editorView = atom.views.getView(editor)
      @setJumpMode(editor)
      label2point  = @getLabel2Point labels, editor, pattern
      label2target = @getLabel2Target label2point, {labelPreference, editorView}
      labelContainer = new LabelContainerView()
      labelContainer.initialize(editor)
      labelContainer.appendChildren _.values(label2target)
      @labelContainers.push labelContainer
      _.extend(@label2target, label2target)

  getLabel2Point: (labels, editor, pattern) ->
    label2point = {}
    [startRow, endRow] = editor.getVisibleRowRange()
    for row in [startRow..endRow]
      break unless labels.length
      if editor.isFoldedAtScreenRow row
        label2point[labels.shift()] = new Point(row, 0)
      else
        lineText = editor.lineTextForScreenRow row
        while match = pattern.exec lineText
          label2point[labels.shift()] = new Point(row, match.index)
          break unless labels.length
    label2point

  # [NOTE]
  # _.mapObject is different between underscore.js and underscore-plus
  # This is underscore-plus.
  getLabel2Target: (label2point, options) ->
    _.mapObject label2point, (label, position) ->
      _.extend options, {label, position}
      LabelView ?= require './label-view'
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
      editorView.addEventListener event, @clearJumpMode.bind(@), true

  unSetJumpMode: (editor) ->
    editorView = atom.views.getView editor
    editorView.classList.remove 'jumpy-jump-mode'
    for event in ['blur', 'click']
      editorView.removeEventListener event, @clearJumpMode.bind(@), true

  clearJumpMode: ->
    @firstChar = null
    @statusBarManager.hide()
    element.remove() for label, element of @label2target
    @label2target = null

    @labelContainer?.destroy()
    @labelContainers = null
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
