express = require 'express'
app = express.createServer()


app.get "/", (req, res) ->
  res.send 'nomnom'

console.log "Listening on port 8000"
app.listen 8000

