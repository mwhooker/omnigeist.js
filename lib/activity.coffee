request = require 'request'
r = require './reddit'
url = require 'url'
SingleUrlExpander = require('url-expander').SingleUrlExpander


class UserActivity
    constructor: (@host, @link, @permalink, @username, @comment, @timestamp, @rank, @others...) ->




class Activity
    constructor: (@url) ->
        @expander = new SingleUrlExpander(@url)
        @expander.expand()

    get: ->

class Reddit extends Activity

    @base_url = 'http://www.reddit.com'

    get: (callback) ->

        info = (c_url) ->

            get_activity = (permalink) ->
                activity_url = url.parse Reddit.base_url
                activity_url.pathname = permalink + '.json'
                request(
                    uri: url.format(activity_url)
                    , (err, res, body) ->
                        console.log err
                        body = JSON.parse(body)
                        comments = new r.Comments body
                        activity = []
                        for comment in comments.comments
                            activity.push new UserActivity(
                                'reddit',
                                c_url,
                                permalink,
                                comment.author,
                                comment.body,
                                comment.created_utc,
                                comment.ups
                            )
                        if activity.length
                            callback(activity)
                    )

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
