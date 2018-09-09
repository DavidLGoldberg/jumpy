wait = (doneFunc, waitTime) ->
    setTimeout ->
        doneFunc()
    , waitTime || 300

module.exports = {wait}
