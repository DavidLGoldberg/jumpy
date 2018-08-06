### global
atom
jasmine describe xdescribe beforeEach afterEach it expect
###
path = require 'path'
{$} = require 'space-pen'
{keydown} = require './helpers/keydown'
{wait} = require './helpers/wait'

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

getDecorationsArrayFromAllEditors = ->
    decorations = []
    atom.workspace.observeTextEditors (editor) ->
        currentTextEditorElement = atom.views.getView(editor)
        return if $(currentTextEditorElement).is ':not(:visible)'

        decorations = decorations.concat(editor.getOverlayDecorations())
    return decorations

# Borrowed from: @lee-dohm
# Public: Indicates whether an element has a command.
#
# * `element` An {HTMLElement} to search.
# * `name` A {String} containing the command name.
#
# Returns a {Boolean} indicating if it has the given command.
hasCommand = (element, name) ->
    commands = atom.commands.findCommands(target: element)
    found = true for command in commands when command.name is name

    found

describe "Jumpy", ->
    [workspaceElement, textEditorElement, textEditor ] = []

    beforeEach ->
        atom.packages.activatePackage 'jumpy'

    beforeEach ->
        atom.packages.activatePackage 'status-bar'

    beforeEach ->
        atom.workspace.open 'test_text.md'

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
        textEditor.setCursorBufferPosition [1,1]

    beforeEach (done) ->
        atom.commands.dispatch textEditorElement, 'jumpy:toggle'
        wait(done)

    afterEach ->
        expect(atom.workspace.getActivePaneItem().isModified()).toBeFalsy()
        atom.workspace.destroy 'test_text.md'

    describe 'activate', ->
        it 'creates the commands', ->
            expect(hasCommand(workspaceElement, 'jumpy:toggle')).toBeTruthy()
            expect(hasCommand(workspaceElement, 'jumpy:reset')).toBeTruthy()
            expect(hasCommand(workspaceElement, 'jumpy:clear')).toBeTruthy()

    describe 'deactivate', ->
        beforeEach ->
            atom.packages.deactivatePackage 'jumpy'

        it 'destroys the commands', ->
            expect(hasCommand(workspaceElement, 'jumpy:toggle')).toBeFalsy()
            expect(hasCommand(workspaceElement, 'jumpy:reset')).toBeFalsy()
            expect(hasCommand(workspaceElement, 'jumpy:clear')).toBeFalsy()

    describe "when the jumpy:toggle event is triggered", ->
        it "draws correct labels", ->
            decorations = textEditor.getOverlayDecorations()
            expect(decorations.length)
                .toBe NUM_TOTAL_WORDS + NUM_CAMEL_SPECIFIC_MATCHES
            expect(decorations[0].getProperties().item.textContent).toBe 'aa'
            expect(decorations[1].getProperties().item.textContent).toBe 'ab'
            expect(decorations[82].getProperties().item.textContent).toBe 'de'
            expect(decorations[83].getProperties().item.textContent).toBe 'df'
        it "clears beacon effect", ->
            expect(textEditorElement.
                querySelectorAll('span.beacon').length).toBe 0

    describe "when the jumpy:clear event is triggered", ->
        beforeEach (done) ->
            atom.commands.dispatch workspaceElement, 'jumpy:clear'
            wait(done)

        it "clears labels", =>
            expect(textEditorElement
                .classList.contains('jumpy-jump-mode')).toBe false
            expect(textEditor.getOverlayDecorations()).toHaveLength 0

    describe "when the jumpy:toggle event is triggered
    and a click event is fired", ->
        beforeEach (done) ->
            textEditorElement.dispatchEvent new Event 'click'
            wait(done)

        it "jumpy is cleared", ->
            expect(textEditorElement.classList.contains('jumpy-jump-mode'))
                .toBe false

    xdescribe "when the jumpy:toggle event is triggered
    and a scroll event is fired", ->
        it "jumpy is cleared", ->
            # TODO: Finish test for scroll-up
            expect(textEditorElement.classList.contains('jumpy-jump-mode'))
                .toBe false

            # TODO: Finish test for scroll-down
            expect(textEditorElement.classList.contains('jumpy-jump-mode'))
                .toBe false

            # TODO: Finish test for scroll-left
            expect(textEditorElement.classList.contains('jumpy-jump-mode'))
                .toBe false

            # TODO: Finish test for scroll-right
            expect(textEditorElement.classList.contains('jumpy-jump-mode'))
                .toBe false

    describe "when the jumpy:toggle event is triggered
    and hotkeys are entered", ->
        beforeEach (done) ->
            keydown('a')
            wait(done)
        beforeEach (done) ->
            keydown('c')
            wait(done)
        it "jumpy is cleared", ->
            expect(textEditor.getOverlayDecorations().filter (d) ->
                d.properties.item.className == 'jumpy-label').toHaveLength 0

    describe "when the jumpy:toggle event is triggered
    and invalid hotkeys are entered", ->
        beforeEach (done) ->
            keydown('z')
            wait(done)
        beforeEach (done) ->
            keydown('z')
            wait(done)
        it "does nothing", ->
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 1
            expect(cursorPosition.column).toBe 1

    describe "when the jumpy:toggle event is triggered", ->
        it "loads 'jumpy-jump-mode'", ->
            expect(textEditorElement
                .classList.contains('jumpy-jump-mode')).toBeTruthy()

    describe "when the jumpy:toggle event is triggered
    and hotkeys are entered", ->
        beforeEach (done) ->
            keydown('a')
            wait(done)
        beforeEach (done) ->
            keydown('c')
            wait(done)

        it "jumps the cursor", ->
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 0
            expect(cursorPosition.column).toBe 6
            expect(textEditor.getSelectedText()).toBe ''
        it "clears jumpy mode", ->
            expect(textEditorElement.
                classList.contains('jumpy-jump-mode')).not.toBeTruthy()

    # Need to work on this one it's non deterministic!
    xdescribe "when the jumpy:toggle event is triggered
    and hotkeys are entered", ->
        beforeEach (done) ->
            atom.commands.dispatch workspaceElement, 'jumpy:clear'
            wait(done)

        beforeEach (done) ->
            textEditor.setCursorBufferPosition [23, 20]
            textEditor.foldBufferRow(22)
            wait(done)

        beforeEach (done) ->
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            wait(done)

        beforeEach (done) ->
            keydown('d')
            wait(done)

        beforeEach (done) ->
            keydown('i')
            wait(done)

        beforeEach (done) ->
            cursorPosition = textEditor.getCursorScreenPosition()
            expect(cursorPosition.row).toBe 23
            expect(cursorPosition.column).toBe 2
            wait(done)

        beforeEach (done) ->
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            wait(done)

        beforeEach (done) ->
            keydown('d')
            wait(done)

        beforeEach (done) ->
            keydown('h')
            wait(done)

        it "jumps the cursor in folded regions", ->
            cursorPosition = textEditor.getCursorScreenPosition()
            expect(cursorPosition.row).toBe 22
            expect(cursorPosition.column).toBe 0

    # TODO: Need to work on this it's non deterministic!
    xdescribe "when the jumpy:toggle event is triggered
    and hotkeys are entered in succession", ->
        beforeEach (done) ->
            keydown('a')
            wait(done)
        beforeEach (done) ->
            keydown('c')
            wait(done)
        beforeEach (done) ->
            atom.commands.dispatch workspaceElement, 'jumpy:toggle'
            wait(done)
        beforeEach (done) ->
            keydown('b')
            wait(done)
        beforeEach (done) ->
            keydown('e')
            wait(done)
        it "jumps the cursor twice", ->
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 6
            expect(cursorPosition.column).toBe 12

    describe "when the jumpy:toggle event is triggered
    and hotkeys are entered", ->
        beforeEach (done) ->
            keydown('a')
            wait(done)
        beforeEach (done) ->
            keydown('c')
            wait(done, 100) # only there for 150 ms

        it "the beacon animation class is added", ->
            expect(textEditorElement
                .querySelectorAll('.beacon').length)
                .toBe 1

    describe "when the jumpy:toggle event is triggered
    and hotkeys are entered", ->
        beforeEach (done) ->
            keydown('a')
            wait(done) # should be gone after 150 ms
        beforeEach (done) ->
            keydown('c')
            wait(done, 1000) # should be gone after 150 ms

        it "the beacon animation class is removed", ->
            expect(textEditorElement
                .querySelectorAll('.beacon').length)
                .toBe 0

    describe "when the jumpy:toggle event is triggered", ->
        it "updates the status bar", ->
            expect(document.querySelector('#status-bar-jumpy')
                .innerHTML.trim()).toBe 'Jumpy: <span class="status">Jump Mode!</span>'

    describe "when the jumpy:clear event is triggered", ->
        beforeEach (done) ->
            atom.commands.dispatch workspaceElement, 'jumpy:clear'
            wait(done)
        it "clears the status bar", ->
            expect(document.querySelector('#status-bar-jumpy')).toBeNull()

    describe "when the jumpy:clear event is triggered", ->
        beforeEach (done) ->
            atom.commands.dispatch workspaceElement, 'jumpy:clear'
            wait(done)
        beforeEach (done) ->
            atom.commands.dispatch workspaceElement, 'jumpy:toggle'
            wait(done)
        it "does not prevent future status bar changes", ->
            expect(document.querySelector('#status-bar-jumpy .status')
                .innerHTML).toBe 'Jump Mode!'

    describe "when the keydown 'a' event is triggered", ->
        beforeEach (done) ->
            keydown('a')
            wait(done)

        it "updates the status bar with a", ->
            expect(document
                .querySelector '#status-bar-jumpy .status'
                    .innerHTML).toBe 'a'

        # TODO: Need to work on this it's non deterministic!
        xit "removes all labels that don't begin with a", ->
            decorations = textEditor.getOverlayDecorations()
            relevantDecorations = decorations.filter (d) ->
                not d.getProperties().item.classList.contains 'irrelevant'
            expect(relevantDecorations).toHaveLength 26

    describe "when the jumpy:reset event is triggered", ->
        beforeEach (done) ->
            keydown('a')
            wait(done)
        beforeEach (done) ->
            atom.commands.dispatch textEditorElement, 'jumpy:reset'
            wait(done)
        beforeEach (done) ->
            keydown('a')
            wait(done)
        beforeEach (done) ->
            keydown('e')
            wait(done)
        it "clears first entered key and lets a new jump take place", ->
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 0
            expect(cursorPosition.column).toBe 12

    describe "when the jumpy:reset event is triggered", ->
        beforeEach (done) ->
            keydown('a')
            wait(done)
        beforeEach (done) ->
            atom.commands.dispatch textEditorElement, 'jumpy:reset'
            wait(done)
        it "updates the status bar", ->
            expect(document
                .querySelector('#status-bar-jumpy .status')
                    .innerHTML).toBe 'Jump Mode!'

    describe "when the jumpy:reset event is triggered", ->
        beforeEach (done) ->
            keydown('a')
            wait(done)
        beforeEach (done) ->
            atom.commands.dispatch textEditorElement, 'jumpy:reset'
            wait(done)
        beforeEach (done) ->
            keydown('a')
            wait(done)
        beforeEach (done) ->
            atom.commands.dispatch textEditorElement, 'jumpy:reset'
            wait(done)
        beforeEach (done) ->
            atom.commands.dispatch textEditorElement, 'jumpy:clear'
            wait(done)
        beforeEach (done) ->
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            wait(done)
        it "does not prevent next load's status", ->
            expect(document
                .querySelector('#status-bar-jumpy .status')
                    .innerHTML).toBe 'Jump Mode!'

    describe "when the jumpy:reset event is triggered", ->
        beforeEach (done) ->
            keydown('a')
            wait(done)
        beforeEach (done) ->
            atom.commands.dispatch textEditorElement, 'jumpy:reset'
            wait(done)
        it "resets all labels even those that don't begin with a", ->
            decorations = textEditor.getOverlayDecorations()
            relevantDecorations = decorations.filter (d) ->
                not d.getProperties().item.classList.contains 'irrelevant'
            expect(relevantDecorations).toHaveLength NUM_TOTAL_WORDS +
                NUM_CAMEL_SPECIFIC_MATCHES

    describe "when a jump is performed", ->
        beforeEach (done) ->
            keydown('a')
            wait(done)
        beforeEach (done) ->
            keydown('a')
            wait(done)
        it "clears the status bar", ->
            expect(document.querySelector('#status-bar-jumpy')).toBeNull()

    # TODO: This does not currently test vim mode.
    describe "when the a text selection has begun
    before a jumpy:toggle event is triggered", ->
        beforeEach (done) ->
            keydown('a')
            keydown('a')
            wait(done)

        beforeEach (done) ->
            textEditor.selectRight()
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            wait(done)

        beforeEach (done) ->
            keydown('a')
            keydown('e')
            wait(done)

        it "keeps the selection for subsequent jumps", ->
            # these were at the start, probably don't need them
            # atom.commands.dispatch textEditorElement, 'jumpy:clear'
            # atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            expect(textEditor.getSelections()[0].getText()).toBe 'aa ab ac ad '

    # TODO: Fix this
    describe "when a character is entered that has no match", ->
        beforeEach (done) ->
            keydown('z')
            wait(done)

        it "displays a status bar error message", ->
            expect(document
                .getElementById 'status-bar-jumpy'
                    .classList.contains 'no-match').toBeTruthy()

    describe "when a character is entered that has no match", ->
        beforeEach (done) ->
            keydown('z')
            wait(done)
        beforeEach (done) ->
            keydown('a')
            wait(done)
        it "eventually clears the status bar error message", ->
            expect(document
                .querySelector '#status-bar-jumpy'
                    .classList.contains 'no-match').toBeFalsy()
            expect(document
                .querySelector '#status-bar-jumpy .status'
                    .innerHTML == 'a').toBeTruthy()

    describe "when a character is entered that has no match", ->
        beforeEach (done) ->
            keydown('z') # ensure 2 z's with below's
            wait(done)
        beforeEach (done) ->
            keydown('z')
            wait(done)
        it "does not jump", ->
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 1
            expect(cursorPosition.column).toBe 1
        it "leaves the labels up", ->
            decorations = textEditor.getOverlayDecorations()
            relevantDecorations = decorations.filter (d) ->
                not d.getProperties().item.classList.contains 'irrelevant'
            expect(relevantDecorations.length > 0).toBeTruthy()

    # TODO: finish this
    xdescribe "when toggle is called with a split tab", ->
        it "continues to label consecutively", ->
            pane = atom.workspace.paneForItem(textEditor)
            pane.splitRight
                copyActiveItem: true

            # NOTE: This also ensures that I shouldn't have to clear the labels
            # In the test, but rather the code does that! (Because the test
            # setup does one toggle always)
            atom.commands.dispatch workspaceElement, 'jumpy:toggle'

            decorations = getDecorationsArrayFromAllEditors()
            expectedTotalNumberWith2Panes =
                (NUM_TOTAL_WORDS + NUM_CAMEL_SPECIFIC_MATCHES) * 2
            expect(decorations).toHaveLength expectedTotalNumberWith2Panes
            # Beginning of first file
            expect(decorations[0].getProperties().item.textContent).toBe 'aa'
            expect(decorations[1].getProperties().item.textContent).toBe 'ab'

            # End of first file
            expect(decorations[116].getProperties().item.textContent).toBe 'em'
            expect(decorations[117].getProperties().item.textContent).toBe 'en'

            # Beginning of second file
            expect(decorations[118].getProperties().item.textContent).toBe 'eo'
            expect(decorations[119].getProperties().item.textContent).toBe 'ep'

    # Fix
    xdescribe "when toggle is called with 2 tabs open in same pane", ->
        beforeEach ->
            atom.workspace.open 'test_text2.md',
                activatePane: true # Just to be clear!

        beforeEach (done) ->
            # TODO: For this test case,
            # these 2 new instances *MIGHT* be crucial.
            # Or become crucial.  I think it's best to leave these.
            currentTextEditor = atom.workspace.getActiveTextEditor()
            currentTextEditorElement = atom.views.getView(currentTextEditor)

            # This Should clear the first jumpy:toggle and re run it
            # now that we're on the 2nd file.
            atom.commands.dispatch currentTextEditorElement, 'jumpy:toggle'
            wait(done)

        it "continues to label consecutively", ->
            decorations = getDecorationsArrayFromAllEditors()
            expectedTotalNumberWith2TabsOpenInOnePane =
                (NUM_TOTAL_WORDS + NUM_CAMEL_SPECIFIC_MATCHES + 3)
            expect(decorations)
                .toHaveLength expectedTotalNumberWith2TabsOpenInOnePane

    describe "when a jump mode is enabled", ->
        beforeEach (done) ->
            atom.packages.activatePackage 'find-and-replace'
            wait(done, 2000)

        beforeEach (done) ->
            atom.commands.dispatch textEditorElement, 'find-and-replace:show'
            wait(done)

        it "clears when a find-and-replace mini pane is opened", ->
            expect(textEditorElement
                .classList.contains('jumpy-jump-mode')).toBe false
            expect(textEditor.getOverlayDecorations().filter (d) ->
                d.properties.item.className == 'jumpy-label').toHaveLength 0
            expect(workspaceElement
                .querySelectorAll('.find-and-replace')).toHaveLength 1

    describe "when a jump mode is enabled", ->
        beforeEach (done) ->
            atom.packages.activatePackage 'fuzzy-finder'
            wait(done, 2000)

        beforeEach (done) ->
            atom.commands.dispatch textEditorElement, 'fuzzy-finder:toggle-file-finder'
            wait(done)

        it "clears when a fuzzy-finder mini pane is opened", ->
            expect(textEditorElement
                .classList.contains('jumpy-jump-mode')).toBe false
            expect(textEditor.getOverlayDecorations()).toHaveLength 0
            expect(workspaceElement
                .querySelectorAll('.fuzzy-finder')).toHaveLength 1

    # TODO: This test doesn't work.  Also, shouldn't need vim-mode-plus
    # This would need upgrading to Jasmine 3.
    xdescribe "when insert mode is used before jumping", ->
        activationPromise = []
        beforeEach ->
            activationPromise = atom.packages.activatePackage 'vim-mode-plus'

        it "does not leave the editor in a dirty / modified state", ->
            waitsForPromise ->
                activationPromise

            runs ->
                atom.commands.dispatch textEditorElement, 'jumpy:toggle' # turn off the initial from scaffolding
                atom.commands.dispatch textEditorElement, 'vim-mode-plus:activate-insert-mode'
                atom.commands.dispatch textEditorElement, 'jumpy:toggle'
                keydown('a', textEditorElement)
                keydown('a', textEditorElement)
                expect(textEditorElement
                    .classList.contains('jumpy-jump-mode')).toBe false
                # Why don't these get added to the editor text?
                keydown('b', textEditorElement)
                keydown('b', textEditorElement)
                # **************************************************************
                # The the parent afterEach() handles expectations.
                # **************************************************************
