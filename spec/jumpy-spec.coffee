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

    describe "when the jumpy:toggle event is triggered", ->
        it "draws correct labels", ->
            expect(editorView.find('.jumpy.labels')).toExist()
            labels = editorView.find('.jumpy.label')
            expect(labels.length).toBe 84 # 2 less for the 'a's.
            expect(labels[0].innerHTML).toBe 'aa'
            expect(labels[1].innerHTML).toBe 'ab'
            expect(labels[82].innerHTML).toBe 'de'
            expect(labels[83].innerHTML).toBe 'df'
        it "clears beacon effect", ->
            expect(editorView.find('cursors .cursor.beacon')).not.toExist()
        it "only uses jumpy keymaps", ->
            expect(atom.keymap.keyBindings.length).toBe 26 + 5 + 1

    describe "when the jumpy:clear event is triggered", ->
        it "clears labels", ->
            editorView.trigger 'jumpy:clear'
            expect(editorView.find('.jumpy')).not.toExist()

    describe "when the jumpy:toggle event is triggered
        and a mousedown event is fired", ->
        it "jumpy is cleared", ->
            editorView.trigger 'mousedown'
            expect(editorView.find('.jumpy')).not.toExist()

    describe "when the jumpy:toggle event is triggered
        and a scroll event is fired", ->
        it "jumpy is cleared", ->
            editorView.trigger 'scroll'
            expect(editorView.find('.jumpy')).not.toExist()

    describe "when the jumpy:toggle event is triggered
        and hotkeys are entered", ->
        it "jumpy is cleared", ->
            editor.setCursorBufferPosition [1,1]
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:c'
            expect(editorView.find('.jumpy')).not.toExist()

    describe "when the jumpy:toggle event is triggered
        and invalid hotkeys are entered", ->
        it "jumpy is cleared", ->
            editor.setCursorBufferPosition [1,1]
            editorView.trigger 'jumpy:z'
            editorView.trigger 'jumpy:z'
            cursorPosition = editor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 1
            expect(cursorPosition.column).toBe 1

    describe "when the jumpy:toggle event is triggered
        and hotkeys are entered", ->
        it "jumps the cursor", ->
            editor.setCursorBufferPosition [1,1]
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:c'
            cursorPosition = editor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 0
            expect(cursorPosition.column).toBe 6

    describe "when the jumpy:toggle event is triggered
        and hotkeys are entered in succession", ->
        it "jumps the cursor twice", ->
            editor.setCursorBufferPosition [1,1]
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:c'
            editorView.trigger 'jumpy:toggle'
            editorView.trigger 'jumpy:b'
            editorView.trigger 'jumpy:e'
            cursorPosition = editor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 6
            expect(cursorPosition.column).toBe 12

    describe "when the jumpy:toggle event is triggered
        and hotkeys are entered", ->
        it "the beacon animation class is added", ->
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:c'
            expect(editorView.find('.beacon')).toExist()
        it "the beacon animation class is removed", ->
            editorView.trigger 'jumpy:a'
            waitsFor ->
                setTimeout ->
                    editorView.trigger 'jumpy:c'
                ,100 + 10 # max default I'd probably use + a buffer
            runs ->
                expect(editorView.find('.beacon')).not.toExist()

    describe "when the jumpy:toggle event is triggered", ->
        it "updates the status bar", ->
            expect(atom.workspaceView.statusBar
                ?.find('#status-bar-jumpy')).toExist()
            expect(atom.workspaceView.statusBar
                ?.find('#status-bar-jumpy #status').html()).toBe 'Jump Mode!'

    describe "when the jumpy:clear event is triggered", ->
        it "clears the status bar", ->
            editorView.trigger 'jumpy:clear'
            expect(atom.workspaceView.statusBar
                ?.find('#status-bar-jumpy').html()).toBe ''

    describe "when the jumpy:a event is triggered", ->
        it "updates the status bar with a", ->
            editorView.trigger 'jumpy:a'
            expect(atom.workspaceView.statusBar
                ?.find('#status-bar-jumpy #status').html()).toBe 'a'
        it "removes all labels that don't begin with a", ->
            editorView.trigger 'jumpy:a'
            expect(editorView.find('.jumpy.label:not(.irrelevant)').length).toBe 26

    describe "when the jumpy:reset event is triggered", ->
        it "clears first entered key and lets a new jump take place", ->
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:reset'
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:e'
            cursorPosition = editor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 0
            expect(cursorPosition.column).toBe 12

    describe "when the jumpy:reset event is triggered", ->
        it "updates the status bar", ->
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:reset'
            expect(atom.workspaceView.statusBar
                ?.find('#status-bar-jumpy #status').html()).toBe 'Jump Mode!'
        it "resets all labels even those that don't begin with a", ->
            editorView.trigger 'jumpy:a'
            editorView.trigger 'jumpy:reset'
            expect(editorView.find('.jumpy.label:not(.irrelevant)').length).toBe 84
