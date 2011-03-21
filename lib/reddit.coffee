exports.Info = class
    constructor: (@info) ->
        @permalinks = (child.data.permalink for child in @info.data.children)


exports.Comments = class
    constructor: (@body) ->
        @comments = []
        for i in @body
            for j in i.data.children
                if j.kind == 't1'
                    @comments.push j.data
