### global
atom
jasmine describe xdescribe beforeEach it runs waitsForPromise
###
path = require 'path'

NUM_ALPHA_TEST_WORDS = 26 * 3
NUM_ENGLISH_TEXT = 8 - 2 #For a's that are only 1 character.  *'s don't count.
NUM_COLLAPSIBLE_WORDS = 19
NUM_CAMEL_WORDS = 3
NUM_TOTAL_WORDS =
    NUM_ALPHA_TEST_WORDS +
    NUM_ENGLISH_TEXT +
    NUM_COLLAPSIBLE_WORDS +
    NUM_CAMEL_WORDS

NUM_CAMEL_SPECIFIC_MATCHES = 4 + 5 + 3

xdescribe "Jumpy", ->
    [workspaceElement, textEditorElement, textEditor, jumpyPromise] = []

    beforeEach ->
        atom.project.setPaths([path.join(__dirname, 'fixtures')])
        # TODO: Abstract the following out, (DRY) --------------
        workspaceElement = atom.views.getView(atom.workspace)
        # @leedohm helped me with this idiom of workspace size.
        # He found it in the wrap-guide.
        workspaceElement.style.height = "5000px" # big enough
        workspaceElement.style.width = "5000px"
        jasmine.attachToDOM(workspaceElement)
        # TODO: Abstract the following out, (DRY) --------------

        waitsForPromise ->
            atom.workspace.open 'test_text.MD'
            atom.workspace.open 'test_text.MD'

        runs ->
            textEditor = atom.workspace.getActiveTextEditor()
            textEditorElement = atom.views.getView(textEditor)
            jumpyPromise = atom.packages.activatePackage 'jumpy'
            textEditor.setCursorBufferPosition [1,1]
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            # TODO: SPLIT PANE (MOVE TO RIGHT)!

        waitsForPromise ->
            jumpyPromise

    afterEach ->
        expect(atom.workspace.getActivePaneItem().isModified()).toBeFalsy()

    # TODO: IMPLEMENT THIS.  Line 192 `pane.activate()` in jumpy-view.coffee
    # should be enough to make this red to green.
    describe "when jumpy jumps to another pane", ->
        it "focuses the new pane", ->
        it "does not move cursor of original pane", ->
        it "does not make edits (with the entered keys)", ->
