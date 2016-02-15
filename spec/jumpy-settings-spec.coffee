### global
atom
jasmine describe beforeEach it xit runs expect waitsForPromise
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

describe "Jumpy with non default settings on", ->
    [textEditor, textEditorElement, jumpyPromise] = []

    beforeEach ->
        atom.project.setPaths([path.join(__dirname, 'fixtures')])
        # TODO: Abstract the following out, (DRY) --------------
        workspaceElement = atom.views.getView(atom.workspace)
        # @leedohm helped me with this idiom of workspace size.
        # He found it in the wrap-guide.
        workspaceElement.style.height = "5000px" # big enough
        workspaceElement.style.width = "5000px"
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
            jumpyPromise = atom.packages.activatePackage 'jumpy'
            textEditor.setCursorBufferPosition [1,1]
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'

        waitsForPromise ->
            jumpyPromise

    describe "when the jumpy:toggle event is triggered", ->
        it "draws correctly colored labels", ->
            expect(textEditor.getOverlayDecorations()[0].getProperties().item
                .classList.contains 'high-contrast').toBe true
        it "draws labels of the right font size", ->
            expect(textEditor.getOverlayDecorations()[0].getProperties().item
                .style.fontSize).toBe '50%'

    describe "when the jumpy:toggle event is triggered
        and a jump is performed", ->
        xit "contains no beacon", ->
            expect(textEditorElement.find('.cursors .cursor')[0].classList
                .contains 'beacon').toBe false
            atom.commands.dispatch textEditorElement, 'jumpy:a'
            atom.commands.dispatch textEditorElement, 'jumpy:c'
            expect(textEditorElement.shadowRoot.querySelectorAll('.cursors .cursor')[0].classList
                .contains 'beacon').toBe false

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
        it "draws correct labels and jumps appropriately", ->
            atom.commands.dispatch textEditorElement, 'jumpy:clear'
            atom.config.set 'jumpy.matchPattern', '([A-Z]+([0-9a-z])*)|[a-z0-9]{2,}'
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
            atom.commands.dispatch textEditorElement, 'jumpy:e'
            atom.commands.dispatch textEditorElement, 'jumpy:a'
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 30
            expect(cursorPosition.column).toBe 4

            #UNDERSCORES:
            atom.commands.dispatch textEditorElement, 'jumpy:toggle'
            atom.commands.dispatch textEditorElement, 'jumpy:e'
            atom.commands.dispatch textEditorElement, 'jumpy:l'
            cursorPosition = textEditor.getCursorBufferPosition()
            expect(cursorPosition.row).toBe 32
            expect(cursorPosition.column).toBe 5
