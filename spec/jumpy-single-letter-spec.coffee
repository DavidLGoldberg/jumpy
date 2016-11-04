### global
atom
jasmine describe xdescribe beforeEach afterEach it runs expect waitsFor
waitsForPromise
###
path = require 'path'
{$} = require 'space-pen'
{keydown} = require './helpers/keydown'

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
        # TODO: Abstract the following out, (DRY) --------------
        jumpyPromise = atom.packages.activatePackage 'jumpy'
        statusBarPromise = atom.packages.activatePackage 'status-bar'
        jasmine.attachToDOM(workspaceElement)

        waitsForPromise ->
            atom.workspace.open 'test_text_single_letter.md'

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

    describe "when the jumpy:toggle event is triggered
    and first letter entered matches only one label", ->
        # (least surprise + the label doesn't change to reflect that
        # only one needs to be hit)
        it "doesn't jump until second letter is entered", ->
            keydown('b')
            expect(textEditorElement
                .classList.contains('jumpy-jump-mode')).toBe true
