express = require 'express'
geist = require './lib/activity'
LRU = require 'lru-cache'
SingleUrlExpander = require('url-expander').SingleUrlExpander

app = express.createServer()
cache = LRU()

app.configure(() ->
    coffeeDir = __dirname + '/static/coffee'
    publicDir = __dirname + '/static/public/js/lib'
    app.use express.compiler(src: coffeeDir, dest: publicDir, enable: ['coffeescript'])

    app.use(express.methodOverride())
    app.use(express.bodyParser())
    app.use(app.router)
)

app.configure('development', () ->
    app.use(express.static(__dirname + '/static/public'))
    app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))
)

app.configure('production', () ->
    oneYear = 31557600000
    app.use(express.static(__dirname + '/static/public', { maxAge: oneYear }))
    app.use(express.errorHandler())
)

app.get "/", (req, res) ->
    res.send 'hello, world'

app.get "/top", (req, res) ->
    send_activity = (c_url) ->
        key = 'activity:' + c_url
        if activity = cache.get(key)
            console.log "found cached value for #{ c_url }"
            for a in activity
                res.write(JSON.stringify(a))
                res.write('\n')
            res.end()
        else
            all_activity = []
            platform = new geist.Reddit c_url
            platform.fetch()
            platform.on('activity', (activity) ->
                console.log 'event activity'
                all_activity.push activity
                res.write(JSON.stringify(activity))
                res.write('\n')
            )
            platform.on('done', () ->
                console.log "done"
                cache.set(key, all_activity)
                res.end()
            )

    if c_url = cache.get(req.query.url)
        send_activity(c_url)
    else
        expander = new SingleUrlExpander(req.query.url)
        expander.expand()
        expander.on('expanded',
            (originalUrl, expandedUrl) ->
                cache.set(req.query.url, expandedUrl)
                send_activity(expandedUrl)
            )



console.log "Listening on port 8000"
app.listen 8000
