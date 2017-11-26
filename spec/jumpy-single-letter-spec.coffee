### global
atom
jasmine describe xdescribe beforeEach afterEach it expect
###
path = require 'path'
{$} = require 'space-pen'
{keydown} = require './helpers/keydown'
{wait} = require './helpers/wait'

describe "Jumpy", ->
    [workspaceElement, textEditorElement, textEditor] = []

    beforeEach ->
        atom.packages.activatePackage 'jumpy'

    beforeEach ->
        atom.packages.activatePackage 'status-bar'

    beforeEach ->
        atom.workspace.open 'test_text_single_letter.md'

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
        atom.workspace.destroy 'test_text_single_letter.md'

    # (least surprise + the label doesn't change to reflect that
    # only one needs to be hit)
    describe "when the jumpy:toggle event is triggered
    and first letter entered matches only one label", ->
        beforeEach (done) ->
            keydown('b')
            wait(done)

        it "doesn't jump until second letter is entered", ->
            expect(textEditorElement
                .classList.contains('jumpy-jump-mode')).toBe true
