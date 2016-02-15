### global
atom
jasmine describe xdescribe beforeEach afterEach it runs expect waitsForPromise
###
path = require 'path'

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
        jumpyPromise = atom.packages.activatePackage 'jumpy'

        waitsForPromise ->
            atom.workspace.open 'test_long_text.MD'

        runs ->
            textEditor = atom.workspace.getActiveTextEditor()
            textEditorElement = atom.views.getView(textEditor)
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'

        waitsForPromise ->
            jumpyPromise

    afterEach ->
        atom.commands.dispatch textEditorElement, 'jumpy:clear'

    # TODO: Recent patch has slowed down execution of the tests when
    # jasmine.attachToDOM is called.  Even with decoration (performance
    # improvements) this file ('test_long_text.MD') is too large to be loaded!
    # It works non jasmine of course...
    xdescribe "when jumpy:toggle event is triggered on a large file", ->
        it "prints the right labels beyond zz", ->
            decorations = textEditor.getOverlayDecorations()
            expect(decorations[0].getProperties().item.textContent).toBe 'aa'
            expect(decorations[1].getProperties().item.textContent).toBe 'ab'
            expect(decorations[676].getProperties().item.textContent).toBe 'Aa'
            expect(decorations[677].getProperties().item.textContent).toBe 'Ab'
            expect(decorations[676+676]
                .getProperties().item.textContent).toBe 'aA'
            expect(decorations[676+676+1]
                .getProperties().item.textContent).toBe 'aB'
        it "does not print undefined labels beyond zA", ->
            decorations = textEditor.getOverlayDecorations()
            expect(decorations).toHaveLength NUM_TOTAL_WORDS - 2
