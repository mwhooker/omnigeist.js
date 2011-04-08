Encoder = require('./util/htmlEntities.js').Encoder

exports.Info = class
    constructor: (@info) ->
        @permalinks = (child.data.permalink for child in @info.data.children)


exports.Comments = class
    constructor: (@body) ->
        @comments = []
        for i in @body
            for j in i.data.children
                if j.kind == 't1'
                    comment = j.data
                    comment.body_html = Encoder.htmlDecode(comment.body_html)
                    @comments.push comment
