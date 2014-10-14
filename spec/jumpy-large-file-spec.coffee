path = require 'path'
{WorkspaceView} = require 'atom'

NUM_TOTAL_WORDS = 676 + 676 + 676 + 2 # 2 extra

describe "Jumpy", ->
    [editorView, editor, jumpyPromise] = []

    beforeEach ->
        atom.workspaceView = new WorkspaceView
        atom.project.setPaths([path.join(__dirname, 'fixtures')])

        waitsForPromise ->
            atom.workspace.open 'test_long_text.MD'

        runs ->
            atom.workspaceView.attachToDom()
            editorView = atom.workspaceView.getActiveView()
            editor = editorView.getEditor()
            jumpyPromise = atom.packages.activatePackage 'jumpy'
            editorView.trigger 'jumpy:toggle'

        waitsForPromise ->
            jumpyPromise

    describe "when jumpy:toggle event is triggered on a large file", ->
        it "prints the right labels beyond zz", ->
            labels = editorView.find('.jumpy.label')
            expect(labels[0].innerHTML).toBe 'aa'
            expect(labels[1].innerHTML).toBe 'ab'
            expect(labels[676].innerHTML).toBe 'Aa'
            expect(labels[677].innerHTML).toBe 'Ab'
            expect(labels[676+676].innerHTML).toBe 'aA'
            expect(labels[676+676+1].innerHTML).toBe 'aB'
        it "does not print undefined labels beyond zA", ->
            labels = editorView.find('.jumpy.label')
            expect(labels.length)
                .toBe NUM_TOTAL_WORDS - 2
