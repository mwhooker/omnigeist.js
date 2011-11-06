jade = require 'jade'
express = require 'express'
geist = require './lib/activity'
SingleUrlExpander = require('url-expander').SingleUrlExpander
socket = require 'socket.io'
eco = require 'eco'
_ = require 'underscore'
redis = require 'redis'
less = require 'less'

app = express.createServer(express.logger())

app.configure(() ->
    port = parseInt(process.env.PORT || 8000)
    app.set('port', port)
    #app.set('socket.io transports', ['jsonp-polling'])
    staticDir = __dirname + '/static'
    app.use express.compiler(src: '/js', enable: ['coffeescript'])
    app.use express.compiler(src: staticDir, enable: ['less'])

    app.register '.eco',
        compile: (str, options) ->
            (locals) ->
                eco.compile(str, locals)

    app.set('view engine', 'jade')
    app.set('views', __dirname + '/views')
    app.use(express.methodOverride())
    app.use(express.bodyParser())
    app.use(app.router)
    app.settings['view options'] = {
      og_debug: false
    }
)

app.configure('development', () ->
    app.use(express.static(__dirname + '/static'))
    app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))

    app.set('redis', {
        port: 6379
        host: 'localhost'
    })

    app.settings['view options']['host'] = 'http://localhost:' + app.set('port')
    app.settings['view options']['port'] = app.set('port')
    app.settings['view options']['og_debug'] = true
)

app.configure('production', () ->
    app.set('redis', {
        port: 9431
        host: 'bass.redistogo.com'
        auth: process.env.REDIS_AUTH
    })
    oneYear = 31557600000
    app.settings['view options']['host'] = 'http://omnigeist.com'
    app.settings['view options']['port'] = 80
    app.use(express.static(__dirname + '/static', { maxAge: oneYear }))
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

redisClient = redis.createClient(
    app.set('redis').port, app.set('redis').host)

if app.set('redis').auth
    redisClient.auth(app.set('redis').auth)

port = app.set('port')
console.log "Listening on port " + port
app.listen port

io = socket.listen app#,
#    transports: app.set('socket.io transports')


io.sockets.on('connection', (socket) ->
    console.log 'connection'
    socket.on('message', (url) ->
        expander = new SingleUrlExpander(url)
        expander.expand()
        expander.on('expanded',
            (originalUrl, expandedUrl) ->
              fanout(expandedUrl, (activity) ->
                socket.send(activity)
              )
            )
        console.log "message data: #{url}"
    )
)

class ActivityCache
    constructor: (url, @ttl) ->
        @urlKey = 'activity_cache:' + url
        if not @ttl?
            @ttl = 120

    get: (hit, miss) ->
        redisClient.lrange(@urlKey, 0, -1, (err, reply) =>
            if err?
                console.error("error fetching activity from cache: " + err)
            else
                if reply.length
                    hit(_.map(reply, JSON.parse))
                else
                    miss(this)
        )

    addActivity: (activity) ->
        console.log('adding activity to ' + @urlKey)
        redisClient.lpush(@urlKey, JSON.stringify(activity))
        if @ttl > 0
            redisClient.expire(@urlKey, @ttl)

logActivity = (activity) ->
  console.log JSON.stringify(activity)

fanout = (expandedUrl, callback) ->
    cache = new ActivityCache(expandedUrl, 0)
    cache.get(
        (activity) ->
            _.each(activity, (i) ->
                callback(i)
            )
        ,(cache) ->
            _.each([geist.Disqus, geist.Reddit, geist.HackerNews, geist.Digg], (platform) ->
                p = new platform expandedUrl
                p.fetch()
                p.on('activity', (activity) ->
                    cache.addActivity(activity)
                    logActivity(activity)
                    callback(activity)
                )
                p.on('error', (message) ->
                    console.error('got error ' + message + '. skipping')
                )
            )
    )
