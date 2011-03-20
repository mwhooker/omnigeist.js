express = require 'express'
activity = require './lib/activity'
app = express.createServer()



app.configure(() ->
    coffeeDir = __dirname + '/static/coffee'
    publicDir = __dirname + '/static/public/js'
    app.use express.compiler(src: coffeeDir, dest: publicDir, enable: ['coffeescript'])

    app.use(express.methodOverride())
    app.use(express.bodyParser())
    app.use(app.router)
)

app.configure('development', () ->
    console.log __dirname + '/static'
    app.use(express.static(__dirname + '/static/public'))
    app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))
)

app.configure('production', () ->
    console.log "production"
    oneYear = 31557600000
    app.use(express.static(__dirname + '/static/public', { maxAge: oneYear }))
    app.use(express.errorHandler())
)

app.get "/", (req, res) ->
    t = new r.Ta
    res.send t.x()
    #res.send 'nomnom'

app.get "/top", (req, res) ->
    platform = new activity.Reddit req.query.url
    platform.get((activity) ->
        res.end(activity)
    )


console.log "Listening on port 8000"
app.listen 8000
