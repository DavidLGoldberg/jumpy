module.exports =
class StatusBarManager
  constructor: ->
    @span = document.createElement("span")
    @span.className = 'status'

    @element = document.createElement("div")
    @element.id = 'status-bar-jumpy'
    @element.textContent = 'Jumpy: '
    @element.appendChild @span

    @container = document.createElement("div")
    @container.className = "inline-block"
    @container.appendChild @element

  initialize: (@statusBar) ->

  hide: ->
    @element.style.display = 'none'
    @update ''

  show: ->
    @element.style.display = 'inline-block'

  init: ->
    @show()
    @update 'Jump Mode!'


  update: (text) ->
    if text is 'No match!'
      @element.classList.add 'no-match'
    else
      @element.classList.remove 'no-match'

    @span.textContent = text

  attach: ->
    @tile = @statusBar.addLeftTile
      item: @container
      priority: -1

  detach: ->
    @tile.destroy()
