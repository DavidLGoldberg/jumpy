### global
atom
jasmine describe xdescribe beforeEach afterEach it expect
###
path = require 'path'
{wait} = require './helpers/wait'

NUM_TOTAL_WORDS = 676 + 676 + 676 + 2 # 2 extra

describe "Jumpy", ->
    [textEditor, textEditorElement] = []

    beforeEach ->
        atom.packages.activatePackage 'jumpy'

    beforeEach ->
        atom.workspace.open 'test_long_text.md'

    beforeEach ->
        # TODO: Abstract the following out, (DRY) --------------
        jasmine.DEFAULT_TIMEOUT_INTERVAL = 60000
        atom.project.setPaths([path.join(__dirname, 'fixtures')])
        workspaceElement = atom.views.getView(atom.workspace)
        # @leedohm helped me with this idiom of workspace size.
        # He found it in the wrap-guide.
        workspaceElement.style.height = "5000px" # big enough
        workspaceElement.style.width = "5000px"
        jasmine.attachToDOM(workspaceElement)
        # TODO: Abstract the following out, (DRY) --------------

        textEditor = atom.workspace.getActiveTextEditor()
        textEditorElement = atom.views.getView(textEditor)
        # TODO: Need this like the others?
        # textEditor.setCursorBufferPosition [1,1]

    beforeEach (done) ->
        atom.commands.dispatch textEditorElement, 'jumpy:toggle'
        wait(done)

    afterEach ->
        expect(atom.workspace.getActivePaneItem().isModified()).toBeFalsy()
        atom.workspace.destroy 'test_long_text.md'

    # TODO: Recent patch has slowed down execution of the tests when
    # jasmine.attachToDOM is called.  Even with decoration (performance
    # improvements) this file ('test_long_text.MD') is too large to be loaded!
    # It works non jasmine of course...
    describe "when jumpy:toggle event is triggered on a large file", ->
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
