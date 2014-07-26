path = require 'path'
{WorkspaceView} = require 'atom'
Jumpy = require '../lib/jumpy'

describe "Jumpy with non default settings on", ->
    [editorView, editor, jumpyPromise] = []

    beforeEach ->
        atom.workspaceView = new WorkspaceView
        atom.project.setPath(path.join(__dirname, 'fixtures'))
        atom.config.set 'jumpy.highContrast', true
        atom.config.set 'jumpy.fontSize', .50
        atom.config.set 'jumpy.useHomingBeaconEffectOnJumps', false

        waitsForPromise ->
            atom.workspace.open 'test_text'

        runs ->
            atom.workspaceView.attachToDom()
            editorView = atom.workspaceView.getActiveView()
            editor = editorView.getEditor()
            jumpyPromise = atom.packages.activatePackage 'jumpy'
            editorView.trigger 'jumpy:toggle'

        waitsForPromise ->
            jumpyPromise

    describe "when the jumpy:toggle event is triggered", ->
        it "draws correctly colored labels", ->
            expect(editorView.find('.jumpy.label')[0].classList
                .contains 'high-contrast').toBe true
        it "draws labels of the right font size", ->
            expect(editorView.find('.jumpy.label')[0]
                .style.fontSize).toBe '50%'

    describe "when the jumpy:toggle event is triggered
        and a jump is performed", ->
        it "contains no beacon", ->
            editor.setCursorBufferPosition [1,1]
            expect(editorView.find('.cursors .cursor')[0].classList
                .contains 'beacon').toBe false
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:c'
            expect(editorView.find('.cursors .cursor')[0].classList
                .contains 'beacon').toBe false
