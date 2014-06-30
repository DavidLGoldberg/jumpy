{WorkspaceView} = require 'atom'
Jumpy = require '../lib/jumpy'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "Jumpy", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('jumpy')

  describe "when the jumpy:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.jumpy')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'jumpy:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.jumpy')).toExist()
        atom.workspaceView.trigger 'jumpy:toggle'
        expect(atom.workspaceView.find('.jumpy')).not.toExist()

  describe "when the jumpy:toggle event is triggered", ->
    it "prints hotkey overlays", ->
      atom.workspaceView.trigger 'jumpy:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
