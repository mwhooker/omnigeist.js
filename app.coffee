express = require 'express'
activity = require './lib/activity'
app = express.createServer()



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
