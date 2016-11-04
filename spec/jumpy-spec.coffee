### global
atom
jasmine describe xdescribe beforeEach afterEach it runs expect waitsFor
waitsForPromise
###
path = require 'path'
{$} = require 'space-pen'
{keydown} = require './helpers/keydown'

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
    [workspaceElement, textEditorElement, textEditor, jumpyPromise,
        statusBarPromise] = []

    beforeEach ->
        atom.project.setPaths([path.join(__dirname, 'fixtures')])
        # TODO: Abstract the following out, (DRY) --------------
        workspaceElement = atom.views.getView(atom.workspace)
        # @leedohm helped me with this idiom of workspace size.
        # He found it in the wrap-guide.
        workspaceElement.style.height = "5000px" # big enough
        workspaceElement.style.width = "5000px"
        jumpyPromise = atom.packages.activatePackage 'jumpy'
        statusBarPromise = atom.packages.activatePackage 'status-bar'
        jasmine.attachToDOM(workspaceElement)
        # TODO: Abstract the following out, (DRY) --------------

        waitsForPromise ->
            atom.workspace.open 'test_text.md'

        runs ->
            textEditor = atom.workspace.getActiveTextEditor()
            textEditorElement = atom.views.getView(textEditor)
            textEditor.setCursorBufferPosition [1,1]
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'

        waitsForPromise ->
            jumpyPromise
        waitsForPromise ->
            statusBarPromise

    afterEach ->
        expect(atom.workspace.getActivePaneItem().isModified()).toBeFalsy()

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
        it "clears labels", ->
            atom.commands.dispatch workspaceElement, 'jumpy:clear'
            expect(textEditorElement
                .classList.contains('jumpy-jump-mode')).toBe false
            expect(textEditor.getOverlayDecorations()).toHaveLength 0

    describe "when the jumpy:toggle event is triggered
    and a click event is fired", ->
        it "jumpy is cleared", ->
            textEditorElement.dispatchEvent new Event 'click'
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
        it "jumpy is cleared", ->
            keydown('a')
            keydown('c')
            expect(textEditor.getOverlayDecorations().filter (d) ->
                d.properties.item.className == 'jumpy-label').toHaveLength 0

    describe "when the jumpy:toggle event is triggered
    and invalid hotkeys are entered", ->
        it "does nothing", ->
            keydown('z')
            keydown('z')
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 1
            expect(cursorPosition.column).toBe 1

    describe "when the jumpy:toggle event is triggered", ->
        it "loads 'jumpy-jump-mode'", ->
            expect(textEditorElement
                .classList.contains('jumpy-jump-mode')).toBeTruthy()

    describe "when the jumpy:toggle event is triggered
    and hotkeys are entered", ->
        it "jumps the cursor", ->
            keydown('a')
            keydown('c')
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 0
            expect(cursorPosition.column).toBe 6
            expect(textEditor.getSelectedText()).toBe ''
        it "clears jumpy mode", ->
            keydown('a')
            keydown('c')
            expect(textEditorElement.
                classList.contains('jumpy-jump-mode')).not.toBeTruthy()
        it "jumps the cursor in folded regions", ->
            atom.commands.dispatch workspaceElement, 'jumpy:clear'
            textEditor.setCursorBufferPosition [23, 20]
            textEditor.foldBufferRow(22)
            atom.commands.dispatch workspaceElement, 'jumpy:toggle'
            keydown('d')
            keydown('i')
            cursorPosition = textEditor.getCursorScreenPosition()
            expect(cursorPosition.row).toBe 23
            expect(cursorPosition.column).toBe 2
            atom.commands.dispatch workspaceElement, 'jumpy:toggle'
            keydown('d')
            keydown('h')
            cursorPosition = textEditor.getCursorScreenPosition()
            expect(cursorPosition.row).toBe 22
            expect(cursorPosition.column).toBe 0

    describe "when the jumpy:toggle event is triggered
    and hotkeys are entered in succession", ->
        it "jumps the cursor twice", ->
            keydown('a')
            keydown('c')
            atom.commands.dispatch workspaceElement, 'jumpy:toggle'
            keydown('b')
            keydown('e')
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 6
            expect(cursorPosition.column).toBe 12

    describe "when the jumpy:toggle event is triggered
    and hotkeys are entered", ->
        it "the beacon animation class is added", ->
            keydown('a')
            keydown('c')
            expect(textEditorElement
                .querySelectorAll('.beacon').length)
                .toBe 1
        it "the beacon animation class is removed", ->
            keydown('a')
            waitsFor ->
                ->
                    keydown('c')
            runs ->
                expect(textEditorElement
                    .querySelectorAll('.beacon').length)
                    .toBe 0

    describe "when the jumpy:toggle event is triggered", ->
        it "updates the status bar", ->
            expect(document.querySelector('#status-bar-jumpy')
                .innerHTML.trim()).toBe 'Jumpy: <span class="status">Jump Mode!</span>'

    describe "when the jumpy:clear event is triggered", ->
        it "clears the status bar", ->
            atom.commands.dispatch workspaceElement, 'jumpy:clear'
            expect(document.querySelector('#status-bar-jumpy')
                .style.display).toBe 'none'
        it "does not prevent future status bar changes", ->
            atom.commands.dispatch workspaceElement, 'jumpy:clear'
            atom.commands.dispatch workspaceElement, 'jumpy:toggle'
            expect(document.querySelector('#status-bar-jumpy .status')
                .innerHTML).toBe 'Jump Mode!'

    describe "when the keydown 'a' event is triggered", ->
        it "updates the status bar with a", ->
            keydown('a')
            expect(document
                .querySelector '#status-bar-jumpy .status'
                    .innerHTML).toBe 'a'
        it "removes all labels that don't begin with a", ->
            keydown('a')
            decorations = textEditor.getOverlayDecorations()
            relevantDecorations = decorations.filter (d) ->
                not d.getProperties().item.classList.contains 'irrelevant'
            expect(relevantDecorations).toHaveLength 26

    describe "when the jumpy:reset event is triggered", ->
        it "clears first entered key and lets a new jump take place", ->
            keydown('a')
            atom.commands.dispatch textEditorElement, 'jumpy:reset'
            keydown('a')
            keydown('e')
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 0
            expect(cursorPosition.column).toBe 12

    describe "when the jumpy:reset event is triggered", ->
        it "updates the status bar", ->
            keydown('a')
            atom.commands.dispatch textEditorElement, 'jumpy:reset'
            expect(document
                .querySelector('#status-bar-jumpy .status')
                    .innerHTML).toBe 'Jump Mode!'
        it "does not prevent next load's status", ->
            keydown('a')
            atom.commands.dispatch textEditorElement, 'jumpy:reset'
            atom.commands.dispatch textEditorElement, 'jumpy:clear'
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            expect(document
                .querySelector('#status-bar-jumpy .status')
                    .innerHTML).toBe 'Jump Mode!'
            expect(document
                .querySelector('#status-bar-jumpy')
                    .style.display).toNotBe 'none'
        it "resets all labels even those that don't begin with a", ->
            keydown('a')
            atom.commands.dispatch textEditorElement, 'jumpy:reset'
            decorations = textEditor.getOverlayDecorations()
            relevantDecorations = decorations.filter (d) ->
                not d.getProperties().item.classList.contains 'irrelevant'
            expect(relevantDecorations).toHaveLength NUM_TOTAL_WORDS +
                NUM_CAMEL_SPECIFIC_MATCHES

    describe "when a jump is performed", ->
        it "clears the status bar", ->
            keydown('a')
            keydown('a')
            expect(document
                .querySelector('#status-bar-jumpy .status').innerHTML).toBe ''
            expect(document
                .querySelector('#status-bar-jumpy').style.display).toBe 'none'

    # TODO: This does not currently test vim mode.
    describe "when the a text selection has begun
    before a jumpy:toggle event is triggered", ->
        it "keeps the selection for subsequent jumps", ->
            atom.commands.dispatch textEditorElement, 'jumpy:clear'
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            keydown('a')
            keydown('a')
            textEditor.selectRight()
            textEditor.selectRight()
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            keydown('a')
            keydown('e')
            expect(textEditor.getSelections()[0].getText()).toBe 'aa ab ac ad '

    describe "when a character is entered that has no match", ->
        it "displays a status bar error message", ->
            keydown('z')
            expect(document
                .querySelector '#status-bar-jumpy'
                    .classList.contains 'no-match').toBeTruthy()
            expect(document
                .querySelector '#status-bar-jumpy .status'
                    .innerHTML == 'No Match!').toBeTruthy()
        it "eventually clears the status bar error message", ->
            keydown('z')
            keydown('a')
            expect(document
                .querySelector '#status-bar-jumpy'
                    .classList.contains 'no-match').toBeFalsy()
            expect(document
                .querySelector '#status-bar-jumpy .status'
                    .innerHTML == 'a').toBeTruthy()
        it "does not jump", ->
            keydown('z')
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 1
            expect(cursorPosition.column).toBe 1
        it "leaves the labels up", ->
            keydown('z')
            decorations = textEditor.getOverlayDecorations()
            relevantDecorations = decorations.filter (d) ->
                not d.getProperties().item.classList.contains 'irrelevant'
            expect(relevantDecorations.length > 0).toBeTruthy()

    describe "when toggle is called with a split tab", ->
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

    describe "when toggle is called with 2 tabs open in same pane", ->
        it "continues to label consecutively", ->
            waitsForPromise ->
                atom.workspace.open 'test_text2.md',
                    activatePane: true # Just to be clear!

            runs ->
                # TODO: For this test case,
                # these 2 new instances *MIGHT* be crucial.
                # Or become crucial.  I think it's best to leave these.
                currentTextEditor = atom.workspace.getActiveTextEditor()
                currentTextEditorElement = atom.views.getView(currentTextEditor)

                # This Should clear the first jumpy:toggle and re run it
                # now that we're on the 2nd file.
                atom.commands.dispatch currentTextEditorElement, 'jumpy:toggle'

                decorations = getDecorationsArrayFromAllEditors()
                expectedTotalNumberWith2TabsOpenInOnePane =
                    (NUM_TOTAL_WORDS + NUM_CAMEL_SPECIFIC_MATCHES + 3)
                expect(decorations)
                    .toHaveLength expectedTotalNumberWith2TabsOpenInOnePane

    describe "when a jump mode is enabled", ->
        activationPromise = []
        beforeEach ->
            activationPromise = atom.packages.activatePackage 'find-and-replace'

        it "clears when a find-and-replace mini pane is opened", ->
            atom.commands.dispatch textEditorElement, 'find-and-replace:show'

            waitsForPromise ->
                activationPromise

            runs ->
                expect(textEditorElement
                    .classList.contains('jumpy-jump-mode')).toBe false
                expect(textEditor.getOverlayDecorations().filter (d) ->
                    d.properties.item.className == 'jumpy-label').toHaveLength 0
                expect(workspaceElement
                    .querySelectorAll('.find-and-replace')).toHaveLength 1

    # FIXME: This broke on the beta build.  They probably don't want you to
    # use the workspace element? Also, note that I shouldn't have to dispatch twice
    # not sure *why* that was there.
    # NOTE: The functionality *does work* in the beta.
    xdescribe "when a jump mode is enabled", ->
        activationPromise = []
        beforeEach ->
            activationPromise = atom.packages.activatePackage 'fuzzy-finder'

        it "clears when a fuzzy-finder mini pane is opened", ->
            atom.commands.dispatch textEditorElement,
                'fuzzy-finder:toggle-file-finder'

            waitsForPromise ->
                activationPromise

            runs ->
                atom.commands.dispatch textEditorElement,
                    'fuzzy-finder:toggle-file-finder'
                expect(textEditorElement
                    .classList.contains('jumpy-jump-mode')).toBe false
                expect(textEditor.getOverlayDecorations()).toHaveLength 0
                expect(workspaceElement
                    .querySelectorAll('.fuzzy-finder')).toHaveLength 1

    # TODO: This test doesn't work.  Also, shouldn't need vim-mode-plus
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
