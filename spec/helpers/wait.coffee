wait = (doneFunc, waitTime) ->
    setTimeout ->
        doneFunc()
    , waitTime || 30

module.exports = {wait}
