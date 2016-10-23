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

    it 'will open a file when selected with jumpy',  ->
        file = path.join DIR, 'test_text.md'
        element = atom.document.querySelector "[data-path=\"#{file}\"]"
        spyOn element, 'dispatchEvent'
        atom.commands.dispatch workspaceElement, 'jumpy:a'
        atom.commands.dispatch workspaceElement, 'jumpy:c'
        expect(element.dispatchEvent).toHaveBeenCalled()
        arg = element.dispatchEvent.mostRecentCall.args[0]
        expect(arg instanceof MouseEvent).toBe yes
        expect(arg.type).toEqual 'mousedown'

    it 'will open/close directories when selected with jumpy', ->
        dir = atom.document.querySelector '.tree-view .directory'
        expect(dir.classList.contains 'expanded').toBe true
        atom.commands.dispatch workspaceElement, 'jumpy:a'
        atom.commands.dispatch workspaceElement, 'jumpy:a'
        expect(dir.classList.contains 'collapsed').toBe true
