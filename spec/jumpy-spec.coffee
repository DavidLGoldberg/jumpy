path = require 'path'
{Views, Commands} = require 'atom'

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

describe "Jumpy", ->
    [workspaceElement, textEditorElement, textEditor, jumpyPromise, statusBarPromise] = []

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

        runs ->
            textEditor = atom.workspace.getActiveTextEditor()
            textEditorElement = atom.views.getView(textEditor)
            jumpyPromise = atom.packages.activatePackage 'jumpy'
            statusBarPromise = atom.packages.activatePackage 'status-bar'
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            # do waitForStatusBar = =>
            #     if not (sb = atom.workspaceView.statusBar)
            #         setTimeout waitForStatusBar, 100
            #         return

        waitsForPromise ->
            jumpyPromise
        waitsForPromise ->
            statusBarPromise

    describe "when the jumpy:toggle event is triggered", ->
        it "draws correct labels", ->
            labels = textEditorElement.querySelectorAll('.jumpy.label')
            expect(labels.length)
                .toBe NUM_TOTAL_WORDS + NUM_CAMEL_SPECIFIC_MATCHES
            expect(labels[0].innerHTML).toBe 'aa'
            expect(labels[1].innerHTML).toBe 'ab'
            expect(labels[82].innerHTML).toBe 'de'
            expect(labels[83].innerHTML).toBe 'df'
        it "clears beacon effect", ->
            expect(textEditorElement.
                querySelectorAll('cursors .cursor.beacon')).not.toExist()
        it "only uses jumpy keymaps", ->
            expect(atom.keymap.keyBindings.length).toBe (26 * 2) + 5 + 1

    describe "when the jumpy:clear event is triggered", ->
        it "clears labels", ->
            atom.commands.dispatch workspaceElement, 'jumpy:clear'
            expect(textEditorElement.querySelectorAll('.jumpy')).not.toExist()

    describe "when the jumpy:toggle event is triggered
        and a mousedown event is fired", ->
        it "jumpy is cleared", ->
            atom.commands.dispatch workspaceElement, 'mousedown'
            expect(textEditorElement.querySelectorAll('.jumpy')).not.toExist()

    describe "when the jumpy:toggle event is triggered
        and a scroll event is fired", ->
        it "jumpy is cleared", ->
            atom.commands.dispatch workspaceElement, 'scroll'
            expect(textEditorElement.querySelectorAll('.jumpy')).not.toExist()

    describe "when the jumpy:toggle event is triggered
        and hotkeys are entered", ->
        it "jumpy is cleared", ->
            textEditor.setCursorBufferPosition [1,1]
            atom.commands.dispatch workspaceElement, 'jumpy:a'
            atom.commands.dispatch workspaceElement, 'jumpy:c'
            expect(textEditorElement.querySelectorAll('.jumpy')).not.toExist()

    describe "when the jumpy:toggle event is triggered
        and invalid hotkeys are entered", ->
        it "jumpy is cleared", ->
            textEditor.setCursorBufferPosition [1,1]
            atom.commands.dispatch workspaceElement, 'jumpy:z'
            atom.commands.dispatch workspaceElement, 'jumpy:z'
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 1
            expect(cursorPosition.column).toBe 1

    describe "when the jumpy:toggle event is triggered
        and hotkeys are entered", ->
        it "jumps the cursor", ->
            textEditor.setCursorBufferPosition [1,1]
            atom.commands.dispatch workspaceElement, 'jumpy:a'
            atom.commands.dispatch workspaceElement, 'jumpy:c'
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 0
            expect(cursorPosition.column).toBe 6
            expect(textEditor.getSelectedText()).toBe ''
        it "jumps the cursor in folded regions", ->
            atom.commands.dispatch workspaceElement, 'jumpy:clear'
            textEditor.setCursorBufferPosition [23, 20]
            textEditor.foldCurrentRow()
            atom.commands.dispatch workspaceElement, 'jumpy:toggle'
            atom.commands.dispatch workspaceElement, 'jumpy:d'
            atom.commands.dispatch workspaceElement, 'jumpy:i'
            cursorPosition = textEditor.getCursorScreenPosition()
            expect(cursorPosition.row).toBe 23
            expect(cursorPosition.column).toBe 2
            atom.commands.dispatch workspaceElement, 'jumpy:toggle'
            atom.commands.dispatch workspaceElement, 'jumpy:d'
            atom.commands.dispatch workspaceElement, 'jumpy:h'
            cursorPosition = textEditor.getCursorScreenPosition()
            expect(cursorPosition.row).toBe 22
            expect(cursorPosition.column).toBe 0

    describe "when the jumpy:toggle event is triggered
        and hotkeys are entered in succession", ->
        it "jumps the cursor twice", ->
            textEditor.setCursorBufferPosition [1,1]
            atom.commands.dispatch workspaceElement, 'jumpy:a'
            atom.commands.dispatch workspaceElement, 'jumpy:c'
            atom.commands.dispatch workspaceElement, 'jumpy:toggle'
            atom.commands.dispatch workspaceElement, 'jumpy:b'
            atom.commands.dispatch workspaceElement, 'jumpy:e'
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 6
            expect(cursorPosition.column).toBe 12

    xdescribe "when the jumpy:toggle event is triggered
        and hotkeys are entered", ->
        it "the beacon animation class is added", ->
            atom.commands.dispatch workspaceElement, 'jumpy:a'
            atom.commands.dispatch workspaceElement, 'jumpy:c'
            expect(textEditorElement.querySelectorAll('.beacon'))
                .toExist()
        it "the beacon animation class is removed", ->
            atom.commands.dispatch workspaceElement, 'jumpy:a'
            waitsFor ->
                setTimeout ->
                    atom.commands.dispatch workspaceElement, 'jumpy:c'
                ,100 + 10 # max default I'd probably use + a buffer
            runs ->
                expect(textEditorElement.querySelectorAll('.beacon'))
                    .not.toExist()

    xdescribe "when the jumpy:toggle event is triggered", ->
        it "updates the status bar", ->
            expect(workspaceElement.statusBar
                ?.querySelectorAll('#status-bar-jumpy')).toExist()
            expect(workspaceElement.statusBar
                ?.querySelectorAll('#status-bar-jumpy .status').html()).toBe 'Jump Mode!'

    xdescribe "when the jumpy:clear event is triggered", ->
        it "clears the status bar", ->
            textEditorElement.trigger 'jumpy:clear'
            expect(atom.workspaceView.statusBar
                ?.querySelectorAll('#status-bar-jumpy').html()).toBe ''

    xdescribe "when the jumpy:a event is triggered", ->
        it "updates the status bar with a", ->
            textEditorElement.trigger 'jumpy:a'
            expect(atom.workspaceView.statusBar
                ?.querySelectorAll('#status-bar-jumpy .status').html()).toBe 'a'
        it "removes all labels that don't begin with a", ->
            textEditorElement.trigger 'jumpy:a'
            expect(textEditorElement.querySelectorAll('.jumpy.label:not(.irrelevant)')
                .length).toBe 26

    describe "when the jumpy:reset event is triggered", ->
        it "clears first entered key and lets a new jump take place", ->
            atom.commands.dispatch textEditorElement, 'jumpy:a'
            atom.commands.dispatch textEditorElement, 'jumpy:reset'
            atom.commands.dispatch textEditorElement, 'jumpy:a'
            atom.commands.dispatch textEditorElement, 'jumpy:e'
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 0
            expect(cursorPosition.column).toBe 12

    describe "when the jumpy:reset event is triggered", ->
        xit "updates the status bar", ->
            textEditorElement.trigger 'jumpy:a'
            textEditorElement.trigger 'jumpy:reset'
            expect(atom.workspaceView.statusBar
                ?.querySelectorAll('#status-bar-jumpy .status').html()).toBe 'Jump Mode!'
        it "resets all labels even those that don't begin with a", ->
            atom.commands.dispatch textEditorElement, 'jumpy:a'
            atom.commands.dispatch textEditorElement, 'jumpy:reset'
            expect(textEditorElement.querySelectorAll('.jumpy.label:not(.irrelevant)')
                .length).toBe NUM_TOTAL_WORDS + NUM_CAMEL_SPECIFIC_MATCHES

    describe "when the a text selection has begun
        before a jumpy:toggle event is triggered", ->
        it "keeps the selection for subsequent jumps", ->
            atom.commands.dispatch textEditorElement, 'jumpy:clear'
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            atom.commands.dispatch textEditorElement, 'jumpy:a'
            atom.commands.dispatch textEditorElement, 'jumpy:a'
            textEditor.selectRight()
            textEditor.selectRight()
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            atom.commands.dispatch textEditorElement, 'jumpy:a'
            atom.commands.dispatch textEditorElement, 'jumpy:e'
            expect(textEditor.getSelections()[0].getText()).toBe 'aa ab ac ad '

    describe "when a character is entered that no label has a match for", ->
        xit "displays a status bar error message", ->
            textEditorElement.trigger 'jumpy:z'
            expect(atom.workspaceView.statusBar
                ?.querySelectorAll('#status-bar-jumpy')
                    .hasClass 'no-match').toBeTruthy()
            expect(atom.workspaceView.statusBar
                ?.querySelectorAll('#status-bar-jumpy .status')
                    .html() == 'No match!').toBeTruthy()
        xit "eventually clears the status bar error message", ->
            textEditorElement.trigger 'jumpy:toggle'
            textEditorElement.trigger 'jumpy:z'
            textEditorElement.trigger 'jumpy:a'
            expect(atom.workspaceView.statusBar
                ?.querySelectorAll '#status-bar-jumpy'
                    .hasClass 'no-match').toBeFalsy()
            expect(atom.workspaceView.statusBar
                ?.querySelectorAll('#status-bar-jumpy .status')
                    .html() == 'a').toBeTruthy()
        it "does not jump", ->
            textEditor.setCursorBufferPosition [1,1]
            atom.commands.dispatch textEditorElement, 'jumpy:z'
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 1
            expect(cursorPosition.column).toBe 1
        it "leaves the labels up", ->
            textEditor.setCursorBufferPosition [1,1]
            atom.commands.dispatch textEditorElement, 'jumpy:z'
            relevantLabels = textEditorElement.querySelectorAll('.label:not(.irrelevant)')
            expect(relevantLabels.length > 0).toBeTruthy()
