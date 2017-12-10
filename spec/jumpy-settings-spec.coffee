### global
atom
jasmine describe beforeEach it xit runs expect waitsForPromise
###
path = require 'path'
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

describe "Jumpy with non default settings on", ->
    [textEditor, textEditorElement] = []

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
        # TODO: Abstract the following out, (DRY) ---------------

        atom.config.set 'jumpy.highContrast', true
        atom.config.set 'jumpy.fontSize', .50
        atom.config.set 'jumpy.useHomingBeaconEffectOnJumps', false
        atom.config.set 'jumpy.matchPattern', '([\\w]){2,}' # old Jumpy default

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

    describe "when the jumpy:toggle event is triggered", ->
        it "draws correctly colored labels", ->
            expect(textEditor.getOverlayDecorations()[0].getProperties().item
                .classList.contains 'high-contrast').toBe true
        it "draws labels of the right font size", ->
            expect(textEditor.getOverlayDecorations()[0].getProperties().item
                .style.fontSize).toBe '50%'

    describe "when the jumpy:toggle event is triggered
        and a jump is performed", ->
        it "contains no beacon", ->
            expect(textEditorElement.
                querySelectorAll('span.beacon').length).toBe 0
            keydown('a')
            keydown('c')
            expect(textEditorElement.
                querySelectorAll('span.beacon').length).toBe 0

    describe "when a custom match (jumpy default) is used", ->
        it "draws correct labels", ->
            labels = textEditor.getOverlayDecorations()
            expect(labels.length)
                .toBe NUM_TOTAL_WORDS
            expect(labels[0].getProperties().item.textContent).toBe 'aa'
            expect(labels[1].getProperties().item.textContent).toBe 'ab'
            expect(labels[82].getProperties().item.textContent).toBe 'de'
            expect(labels[83].getProperties().item.textContent).toBe 'df'

    describe "when a custom match is used (camel case)", ->
        # Only read the jumpy.matchPattern once at initialization now.
        beforeEach ->
            atom.packages.deactivatePackage 'jumpy'

        it "draws correct labels and jumps appropriately", ->
            atom.config.set 'jumpy.matchPattern', '([A-Z]+([0-9a-z])*)|[a-z0-9]{2,}'
            activate = atom.packages.activatePackage 'jumpy'

            waitsForPromise ->
                activate

            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            labels = textEditor.getOverlayDecorations()
            expect(labels.length)
                .toBe NUM_TOTAL_WORDS + NUM_CAMEL_SPECIFIC_MATCHES
            # BASE CASE WORDS:
            expect(labels[0].getProperties().item.textContent).toBe 'aa'
            expect(labels[1].getProperties().item.textContent).toBe 'ab'
            expect(labels[82].getProperties().item.textContent).toBe 'de'
            expect(labels[83].getProperties().item.textContent).toBe 'df'

            #CAMELS:
            keydown('e')
            keydown('a')
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 30
            expect(cursorPosition.column).toBe 4

            #UNDERSCORES:
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            keydown('e')
            keydown('l')
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 32
            expect(cursorPosition.column).toBe 5


    describe "when customKeys is used", ->
        # Tests hot swapping of keys.
        # To confusing if this doesn't work for beginner Atom users without an Atom restart.
        beforeEach ->
            atom.commands.dispatch textEditorElement, 'jumpy:toggle' # close default toggle from above before changing settings
            atom.config.set 'jumpy.matchPattern', '([A-Z]+([0-9a-z])*)|[a-z0-9]{2,}'
            atom.config.set 'jumpy.customKeys', ['s', 'd', 'f', 'g', 'h', 'j', 'k', 'l'] # home keys skipping 'a'

        it "draws correct labels", ->
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            labels = textEditor.getOverlayDecorations()
            expect(labels.length)
                .toBe NUM_TOTAL_WORDS + NUM_CAMEL_SPECIFIC_MATCHES

            expect(labels[0].getProperties().item.textContent).toBe 'ss'
            expect(labels[1].getProperties().item.textContent).toBe 'sd'
            expect(labels[82].getProperties().item.textContent).toBe 'Ff'
            expect(labels[83].getProperties().item.textContent).toBe 'Fg'
