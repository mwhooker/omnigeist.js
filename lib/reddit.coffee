class Info
    constructor: (@info) ->
        @permalinks = (child.data.permalink for child in @info.data.children)


exports.Info = Info
