View = require './view'
StatusBarManager = require './status-bar-manager'
{CompositeDisposable, Disposable} = require 'atom'

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
  view: null
  config: Config

  activate: ->
    @subscriptions = new CompositeDisposable
    @statusBarManager = new StatusBarManager

    lowerCharacters = "abcdefghijklmnopqrstuvwxyz"
    upperCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    commands = {}
    for char in (lowerCharacters + upperCharacters).split('')
      do (char) =>
        commands['jumpy:' + char] = =>
          @getView().getKey(char)
    @subscriptions.add atom.commands.add 'atom-workspace', commands

    @subscriptions.add atom.commands.add 'atom-workspace',
      'jumpy:toggle': => @getView().toggle()
      'jumpy:reset':  => @getView().reset()
      'jumpy:clear':  => @getView().clearJumpMode()

  getView: ->
    @view ?= new View(@statusBarManager)

  consumeStatusBar: (statusBar) ->
    @statusBarManager.initialize(statusBar)
    @statusBarManager.attach()
    @subscriptions.add new Disposable =>
      @statusBarManager.detach()

  deactivate: ->
    @view?.destroy()
    @commands?.dispose()
    @subscriptions.dispose()
