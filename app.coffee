jade = require 'jade'
express = require 'express'
geist = require './lib/activity'
LRU = require 'lru-cache'
SingleUrlExpander = require('url-expander').SingleUrlExpander
io = require 'socket.io'
eco = require 'eco'

app = express.createServer()
cache = LRU()

app.configure(() ->
    coffeeDir = __dirname + '/static/coffee'
    publicDir = __dirname + '/static/public/js/lib'
    app.use express.compiler(src: coffeeDir, dest: publicDir, enable: ['coffeescript'])

    app.register '.eco',
        compile: (str, options) ->
            (locals) ->
                eco.compile(str, locals)

    app.set('view engine', 'jade')
    app.set('views', __dirname + '/views')
    app.use(express.methodOverride())
    app.use(express.bodyParser())
    app.use(app.router)
    app.set('view options', {
      og_debug: false
    })
)

app.configure('development', () ->
    app.use(express.static(__dirname + '/static/public'))
    app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))

    app.settings['view options']['host'] = 'http://localhost:8000'
    app.settings['view options']['og_debug'] = true
)

app.configure('production', () ->
    oneYear = 31557600000
    app.use(express.static(__dirname + '/static/public', { maxAge: oneYear }))
    app.use(express.errorHandler())

)

app.get "/", (req, res) ->
    res.render('index')

app.get "/top.html", (req, res) ->
    url = req.query.url
    res.render('top', {
        layout: false
        url: url
    })

app.get "/bookmarklet.js", (req, res) ->
    res.contentType 'js'
    res.render('bookmarklet/client.ejs',
        layout: false
    )

'''
app.get "/top.json", (req, res) ->
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
'''

console.log "Listening on port 8000"
app.listen 8000

socket = io.listen app
socket.on('connection', (client) ->
    console.log 'connection'
    client.on('message', (url) ->
        expander = new SingleUrlExpander(url)
        expander.expand()
        expander.on('expanded',
            (originalUrl, expandedUrl) ->
                
                key = 'activity:' + expandedUrl
                if activity = cache.get key
                    for a in activity
                        client.send a
                else
                    platform = new geist.Reddit expandedUrl
                    platform.fetch()
                    buffer = []
                    platform.on('activity', (activity) ->
                        buffer.push activity
                        client.send activity
                    )
                    platform.on('done', () ->
                        cache.set(key, buffer)
                    )
            )
        console.log "message data: #{url}"
    )
    client.on('disconnect', () ->
    )
)
