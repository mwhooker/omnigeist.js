express = require 'express'
request = require 'request'
url = require 'url'
SingleUrlExpander = require('url-expander').SingleUrlExpander
app = express.createServer()


class Activity
    constructor: (@url) ->
        @expander = new SingleUrlExpander(@url)
        @expander.expand()

    get: ->

class Reddit extends Activity

    @base_url = 'http://www.reddit.com'

    get: (callback) ->
        info = (c_url) ->
            info_url = url.parse Reddit.base_url
            info_url.pathname = '/api/info.json'
            info_url.query = {'url': c_url}
            request(
                uri: url.format(info_url)
                , (err, res, body) ->
                    body = JSON.parse(body)
                    console.log(body.kind)
                )

        @expander.on('expanded',
            (originalUrl, expandedUrl) =>
                c_url = expandedUrl
                info(c_url)
            )

app.get "/", (req, res) ->
    res.send 'nomnom'

app.get "/top", (req, res) ->
    platform = new Reddit req.query.url
    platform.get((activity) ->
        res.end(activity)
    )


console.log "Listening on port 8000"
app.listen 8000

