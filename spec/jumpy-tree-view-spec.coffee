### global
atom jasmine describe xdescribe beforeEach it runs waitsForPromise
###

path = require 'path'

NUM_FILES = 3
NUM_DIRS = 1
DIR = path.join __dirname, 'fixtures'

describe 'jumpy-tree-view', ->

    {workspaceElement} = {}

    beforeEach ->
        atom.project.setPaths [DIR]
        workspaceElement = atom.views.getView atom.workspace
        workspaceElement.style.height = '5000px'
        workspaceElement.style.width = '5000px'
        jasmine.attachToDOM workspaceElement
        waitsForPromise -> atom.packages.activatePackage 'tree-view'
        runs -> atom.commands.dispatch 'tree-view:show'
        waitsForPromise ->
            promise = atom.packages.activatePackage 'jumpy'
            atom.commands.dispatch workspaceElement, 'jumpy:toggle'
            promise

    afterEach ->
        atom.commands.dispatch workspaceElement, 'jumpy:clear'

    it 'adds labels to each element in the tree', ->
        labels = atom.document.querySelectorAll '.tree-view .jumpy-label'
        expect(labels.length).toBe NUM_DIRS + NUM_FILES

    xit 'will open a file when selected with jumpy',  ->
        # TODO: This doesn't work. Maybe use spies & stubs instead.
        atom.commands.dispatch workspaceElement, 'jump:a'
        atom.commands.dispatch workspaceElement, 'jump:c'
        editor = atom.workspace.getActivePaneItem()
        file = editor?.buffer.file.path
        expect(file).toBe path.join DIR, 'test_text.md'

    it 'will open/close directories when selected with jumpy', ->
        dir = atom.document.querySelector '.tree-view .directory'
        expect(dir.classList.contains 'expanded').toBe true
        atom.commands.dispatch workspaceElement, 'jumpy:a'
        atom.commands.dispatch workspaceElement, 'jumpy:a'
        expect(dir.classList.contains 'collapsed').toBe true
