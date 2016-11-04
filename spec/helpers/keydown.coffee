keydown = (key, element) ->
  element = element || document.activeElement
  event = new KeyboardEvent 'keydown',
    code: "Key#{key.toUpperCase()}"
    key: key
  element.dispatchEvent event

module.exports = {keydown}
