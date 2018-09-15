wait = (doneFunc, waitTime) ->
    setTimeout ->
        doneFunc()
    , waitTime || 600

module.exports = {wait}
