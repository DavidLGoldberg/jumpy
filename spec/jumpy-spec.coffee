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
        workspaceElement = atom.views.getView(atom.workspace)
        workspaceElement.style.height = "5000px" # big enough
        workspaceElement.style.width = "5000px"
        jasmine.attachToDOM(workspaceElement)

        waitsForPromise ->
            atom.workspace.open 'test_text.MD'

        runs ->
            textEditor = atom.workspace.getActiveTextEditor()
            textEditorElement = atom.views.getView(textEditor)
            jumpyPromise = atom.packages.activatePackage 'jumpy'
            statusBarPromise = atom.packages.activatePackage 'status-bar'
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'

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
            textEditorElement.trigger 'mousedown'
            expect(textEditorElement.querySelectorAll('.jumpy')).not.toExist()

    describe "when the jumpy:toggle event is triggered
        and a scroll event is fired", ->
        it "jumpy is cleared", ->
            textEditorElement.trigger 'scroll'
            expect(textEditorElement.querySelectorAll('.jumpy')).not.toExist()

    describe "when the jumpy:toggle event is triggered
        and hotkeys are entered", ->
        it "jumpy is cleared", ->
            editor.setCursorBufferPosition [1,1]
            textEditorElement.trigger 'jumpy:a'
            textEditorElement.trigger 'jumpy:c'
            expect(textEditorElement.querySelectorAll('.jumpy')).not.toExist()

    describe "when the jumpy:toggle event is triggered
        and invalid hotkeys are entered", ->
        it "jumpy is cleared", ->
            editor.setCursorBufferPosition [1,1]
            textEditorElement.trigger 'jumpy:z'
            textEditorElement.trigger 'jumpy:z'
            cursorPosition = editor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 1
            expect(cursorPosition.column).toBe 1

    describe "when the jumpy:toggle event is triggered
        and hotkeys are entered", ->
        it "jumps the cursor", ->
            editor.setCursorBufferPosition [1,1]
            textEditorElement.trigger 'jumpy:a'
            textEditorElement.trigger 'jumpy:c'
            cursorPosition = editor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 0
            expect(cursorPosition.column).toBe 6
            expect(editor.getSelectedText()).toBe ''
        it "jumps the cursor in folded regions", ->
            textEditorElement.trigger 'jumpy:clear'
            editor.setCursorBufferPosition [23, 20]
            editor.foldCurrentRow()
            textEditorElement.trigger 'jumpy:toggle'
            textEditorElement.trigger 'jumpy:d'
            textEditorElement.trigger 'jumpy:i'
            cursorPosition = editor.getCursorScreenPosition()
            expect(cursorPosition.row).toBe 23
            expect(cursorPosition.column).toBe 2
            textEditorElement.trigger 'jumpy:toggle'
            textEditorElement.trigger 'jumpy:d'
            textEditorElement.trigger 'jumpy:h'
            cursorPosition = editor.getCursorScreenPosition()
            expect(cursorPosition.row).toBe 22
            expect(cursorPosition.column).toBe 0

    describe "when the jumpy:toggle event is triggered
        and hotkeys are entered in succession", ->
        it "jumps the cursor twice", ->
            editor.setCursorBufferPosition [1,1]
            textEditorElement.trigger 'jumpy:a'
            textEditorElement.trigger 'jumpy:c'
            textEditorElement.trigger 'jumpy:toggle'
            textEditorElement.trigger 'jumpy:b'
            textEditorElement.trigger 'jumpy:e'
            cursorPosition = editor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 6
            expect(cursorPosition.column).toBe 12

    describe "when the jumpy:toggle event is triggered
        and hotkeys are entered", ->
        it "the beacon animation class is added", ->
            textEditorElement.trigger 'jumpy:a'
            textEditorElement.trigger 'jumpy:c'
            expect(textEditorElement.querySelectorAll('.beacon')).toExist()
        it "the beacon animation class is removed", ->
            textEditorElement.trigger 'jumpy:a'
            waitsFor ->
                setTimeout ->
                    textEditorElement.trigger 'jumpy:c'
                ,100 + 10 # max default I'd probably use + a buffer
            runs ->
                expect(textEditorElement.querySelectorAll('.beacon')).not.toExist()

    describe "when the jumpy:toggle event is triggered", ->
        it "updates the status bar", ->
            expect(atom.workspaceView.statusBar
                ?.querySelectorAll('#status-bar-jumpy')).toExist()
            expect(atom.workspaceView.statusBar
                ?.querySelectorAll('#status-bar-jumpy .status').html()).toBe 'Jump Mode!'

    describe "when the jumpy:clear event is triggered", ->
        it "clears the status bar", ->
            textEditorElement.trigger 'jumpy:clear'
            expect(atom.workspaceView.statusBar
                ?.querySelectorAll('#status-bar-jumpy').html()).toBe ''

    describe "when the jumpy:a event is triggered", ->
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
            textEditorElement.trigger 'jumpy:a'
            textEditorElement.trigger 'jumpy:reset'
            textEditorElement.trigger 'jumpy:a'
            textEditorElement.trigger 'jumpy:e'
            cursorPosition = editor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 0
            expect(cursorPosition.column).toBe 12

    describe "when the jumpy:reset event is triggered", ->
        it "updates the status bar", ->
            textEditorElement.trigger 'jumpy:a'
            textEditorElement.trigger 'jumpy:reset'
            expect(atom.workspaceView.statusBar
                ?.querySelectorAll('#status-bar-jumpy .status').html()).toBe 'Jump Mode!'
        it "resets all labels even those that don't begin with a", ->
            textEditorElement.trigger 'jumpy:a'
            textEditorElement.trigger 'jumpy:reset'
            expect(textEditorElement.querySelectorAll('.jumpy.label:not(.irrelevant)')
                .length).toBe NUM_TOTAL_WORDS + NUM_CAMEL_SPECIFIC_MATCHES

    describe "when the a text selection has begun
        before a jumpy:toggle event is triggered", ->
        it "keeps the selection for subsequent jumps", ->
            textEditorElement.trigger 'jumpy:clear'
            textEditorElement.trigger 'jumpy:toggle'
            textEditorElement.trigger 'jumpy:a'
            textEditorElement.trigger 'jumpy:a'
            editor.selectRight()
            editor.selectRight()
            textEditorElement.trigger 'jumpy:toggle'
            textEditorElement.trigger 'jumpy:a'
            textEditorElement.trigger 'jumpy:e'
            expect(editor.getSelection(0).getText()).toBe 'aa ab ac ad '

    describe "when the a text selection has begun
        before a jumpy:toggle event is triggered", ->
        it "keeps the selection for subsequent jumps", ->
            textEditorElement.trigger 'jumpy:clear'
            textEditorElement.trigger 'jumpy:toggle'
            textEditorElement.trigger 'jumpy:a'
            textEditorElement.trigger 'jumpy:a'
            editor.selectRight()
            editor.selectRight()
            textEditorElement.trigger 'jumpy:toggle'
            textEditorElement.trigger 'jumpy:a'
            textEditorElement.trigger 'jumpy:e'
            expect(editor.getSelection(0).getText()).toBe 'aa ab ac ad '

    describe "when a character is entered that no label has a match for", ->
        it "displays a status bar error message", ->
            textEditorElement.trigger 'jumpy:z'
            expect(atom.workspaceView.statusBar
                ?.querySelectorAll('#status-bar-jumpy')
                    .hasClass 'no-match').toBeTruthy()
            expect(atom.workspaceView.statusBar
                ?.querySelectorAll('#status-bar-jumpy .status')
                    .html() == 'No match!').toBeTruthy()
        it "eventually clears the status bar error message", ->
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
            editor.setCursorBufferPosition [1,1]
            textEditorElement.trigger 'jumpy:z'
            cursorPosition = editor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 1
            expect(cursorPosition.column).toBe 1
        it "leaves the labels up", ->
            editor.setCursorBufferPosition [1,1]
            textEditorElement.trigger 'jumpy:z'
            relevantLabels = textEditorElement.querySelectorAll('.label:not(.irrelevant)')
            expect(relevantLabels.length > 0).toBeTruthy()
