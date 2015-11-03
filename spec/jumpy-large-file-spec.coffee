path = require 'path'
{Views, Commands} = require 'atom'

NUM_TOTAL_WORDS = 676 + 676 + 676 + 2 # 2 extra

describe "Jumpy", ->
    [textEditor, textEditorElement, jumpyPromise] = []

    beforeEach ->
        atom.project.setPaths([path.join(__dirname, 'fixtures')])
        workspaceElement = atom.views.getView(atom.workspace)
        # @leedohm helped me with this idiom of workspace size.
        # He found it in the wrap-guide.
        workspaceElement.style.height = "5000px" # big enough
        workspaceElement.style.width = "5000px"
        jasmine.attachToDOM(workspaceElement)

        waitsForPromise ->
            atom.workspace.open 'test_long_text.MD'

        runs ->
            textEditor = atom.workspace.getActiveTextEditor()
            textEditorElement = atom.views.getView(textEditor)
            jumpyPromise = atom.packages.activatePackage 'jumpy'
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'

        waitsForPromise ->
            jumpyPromise

    describe "when jumpy:toggle event is triggered on a large file", ->
        it "prints the right labels beyond zz", ->
            labels = textEditorElement.shadowRoot
                .querySelectorAll '.jumpy.label'
            expect(labels[0].innerHTML).toBe 'aa'
            expect(labels[1].innerHTML).toBe 'ab'
            expect(labels[676].innerHTML).toBe 'Aa'
            expect(labels[677].innerHTML).toBe 'Ab'
            expect(labels[676+676].innerHTML).toBe 'aA'
            expect(labels[676+676+1].innerHTML).toBe 'aB'
        it "does not print undefined labels beyond zA", ->
            labels = textEditorElement.shadowRoot
                .querySelectorAll '.jumpy.label'
            expect(labels.length).toBe NUM_TOTAL_WORDS - 2
