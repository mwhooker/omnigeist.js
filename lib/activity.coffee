request = require 'request'
r = require './reddit'
url = require 'url'
SingleUrlExpander = require('url-expander').SingleUrlExpander


class UserActivity
    constructor: (@host, @link, @username, @comment, @timestamp, @others...) ->


class Activity
    constructor: (@url) ->
        @expander = new SingleUrlExpander(@url)
        @expander.expand()

    get: ->

class Reddit extends Activity

    @base_url = 'http://www.reddit.com'

    get: (callback) ->
        get_activity = (permalink) ->
            activity_url = url.parse Reddit.base_url
            activity_url.pathname = permalink + '.json'
            request(
                uri: url.format(activity_url)
                , (err, res, body) ->
                    body = JSON.parse(body)
                )

        info = (c_url) ->
            info_url = url.parse Reddit.base_url
            info_url.pathname = '/api/info.json'
            info_url.query = {'url': c_url}
            request(
                uri: url.format(info_url)
                , (err, res, body) ->
                    if err?
                        console.log err
                    body = JSON.parse body
                    i = new r.Info body
                    for permalink in i.permalinks
                        get_activity(permalink)
                )

        @expander.on('expanded',
            (originalUrl, expandedUrl) =>
                c_url = expandedUrl
                info(c_url)
            )

exports.Reddit = Reddit
