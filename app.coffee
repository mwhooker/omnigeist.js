jade = require 'jade'
express = require 'express'
geist = require './lib/activity'
SingleUrlExpander = require('url-expander').SingleUrlExpander
io = require 'socket.io'
eco = require 'eco'
_ = require 'underscore'
redis = require 'redis'

app = express.createServer()
redisClient = redis.createClient(6379, 'localhost');


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

app.get "/templates.js", (req, res) ->
    res.contentType 'js'
    res.render('bookmarklet/templates.ejs',
        layout: false
    )

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
              fanout(expandedUrl, (activity) ->
                client.send(activity)
              )
            )
        console.log "message data: #{url}"
    )
    client.on('disconnect', () ->
    )
)

class ActivityCache
    constructor: (url) ->
        @urlKey = 'activity_cache:' + url
        #@platformKey = platformName + ':cache'

    get: (success, miss) ->
        redisClient.lrange(@urlKey, 0, -1, (err, reply) =>
            if err?
                console.error("error fetching activity from cache: " + err)
            else
                if reply.length
                    success(_.map(reply, JSON.parse))
                else
                    miss(this)
        )

    addActivity: (activity) ->
        console.log('adding activity to ' + @urlKey)
        redisClient.lpush(@urlKey, JSON.stringify(activity))


fanout = (expandedUrl, callback) ->
    cache = new ActivityCache(expandedUrl)
    cache.get(
        (activity) ->
            _.each(activity, (i) ->
                callback(i)
            )
        ,(cache) ->
            _.each([geist.Reddit, geist.HackerNews], (platform) ->
                p = new platform expandedUrl
                p.fetch()
                p.on('activity', (activity) ->
                    cache.addActivity(activity)
                    callback(activity)
                )
            )
    )
