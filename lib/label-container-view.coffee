class LabelContainerView extends HTMLElement
  initialize: (editor) ->
    @classList.add "jumpy", "jumpy-label-container"
    editorView = atom.views.getView(editor)
    @overlayer = editorView.shadowRoot.querySelector('content[select=".overlayer"]')
    @overlayer.appendChild this

  appendChildren: (children) ->
    for child in children
      @appendChild child

  reset: ->
    for labelElement in @childNodes
      labelElement.reset()

  destroy: ->
    @remove()

module.exports = document.registerElement 'jumpy-label-container',
  prototype: LabelContainerView.prototype
  extends:   'div'
