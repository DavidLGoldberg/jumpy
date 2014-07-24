path = require 'path'
{WorkspaceView} = require 'atom'
Jumpy = require '../lib/jumpy'

describe "Jumpy", ->
    [editorView, editor, jumpyPromise, statusBarPromise] = []

    beforeEach ->
        atom.workspaceView = new WorkspaceView
        atom.project.setPath(path.join(__dirname, 'fixtures'))

        waitsForPromise ->
            atom.workspace.open 'test_text'

        runs ->
            atom.workspaceView.attachToDom()
            editorView = atom.workspaceView.getActiveView()
            editor = editorView.getEditor()
            jumpyPromise = atom.packages.activatePackage 'jumpy'
            statusBarPromise = atom.packages.activatePackage('status-bar')
            editorView.trigger 'jumpy:toggle'

        waitsForPromise ->
            jumpyPromise
        waitsForPromise ->
            statusBarPromise

    describe "when the jumpy:toggle event is triggered a mousedown event is fired", ->
        it "jumpy is cleared", ->
            editorView.trigger 'mousedown'
            expect(editorView.find('.jumpy')).not.toExist()

    describe "when the jumpy:toggle event is triggered a scroll event is fired", ->
        it "jumpy is cleared", ->
            editorView.trigger 'scroll'
            expect(editorView.find('.jumpy')).not.toExist()

    describe "when the jumpy:clear event is triggered", ->
        it "clears labels", ->
            editorView.trigger 'jumpy:clear'
            expect(editorView.find('.jumpy')).not.toExist()

    describe "when the jumpy:toggle event is triggered and hotkeys are entered", ->
        it "jumpy is cleared", ->
            editor.setCursorBufferPosition [1,1]
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:c'
            expect(editorView.find('.jumpy')).not.toExist()

    describe "when the jumpy:toggle event is triggered and hotkeys are entered", ->
        it "jumps the cursor", ->
            editor.setCursorBufferPosition [1,1]
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:c'
            cursorPosition = editor.getCursorBufferPosition()
            expect(cursorPosition.row).toEqual 0
            expect(cursorPosition.column).toEqual 10

    describe "when the jumpy:toggle event is triggered and hotkeys are entered
        in succession", ->
        it "jumps the cursor twice", ->
            editor.setCursorBufferPosition [1,1]
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:c'
            editorView.trigger 'jumpy:toggle'
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:e'
            cursorPosition = editor.getCursorBufferPosition()
            expect(cursorPosition.row).toEqual 1
            expect(cursorPosition.column).toEqual 5

    describe "when the jumpy:toggle event is triggered", ->
        it "draws labels", ->
            # TODO: make this more thorough!
            expect(editorView.find('.jumpy')).toExist()

    describe "when the jumpy:toggle event is triggered", ->
        it "updates the status bar", ->
            expect(atom.workspaceView.statusBar
                ?.find('#status-bar-jumpy')).toExist()
            expect(atom.workspaceView.statusBar
                ?.find('#status-bar-jumpy #status').html()).toBe 'Jump Mode!'

    describe "when the jumpy:clear event is triggered", ->
        it "updates the status bar", ->
            editorView.trigger 'jumpy:clear'
            expect(atom.workspaceView.statusBar
                ?.find('#status-bar-jumpy').html()).toBe ''

    describe "when the jumpy:a event is triggered", ->
        it "updates the status bar", ->
            editorView.trigger 'jumpy:a'
            expect(atom.workspaceView.statusBar
                ?.find('#status-bar-jumpy #status').html()).toBe 'a'

    describe "when the jumpy:reset event is triggered", ->
        it "clears first entered key", ->
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:reset'
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:e'
            cursorPosition = editor.getCursorBufferPosition()
            expect(cursorPosition.row).toEqual 1
            expect(cursorPosition.column).toEqual 5

    describe "when the jumpy:reset event is triggered", ->
        it "updates the status bar", ->
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:reset'
            expect(atom.workspaceView.statusBar
                ?.find('#status-bar-jumpy #status').html()).toBe 'Jump Mode!'
