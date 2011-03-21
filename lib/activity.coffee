request = require 'request'
r = require './reddit'
url = require 'url'
util = require 'util'
events = require 'events'


class UserActivity
    constructor: (@host, @link, @permalink, @username, @comment, @timestamp, @rank, @others...) ->


class Reddit extends events.EventEmitter

    @base_url = 'http://www.reddit.com'

    constructor: (@c_url) ->

    fetch: () ->

        completed_requests = 0
        total_requests = 0

        get_activity = (permalink) =>
            console.log "requesting activity from #{ permalink }"
            activity_url = url.parse Reddit.base_url
            activity_url.pathname = permalink + '.json'
            request(
                uri: url.format(activity_url)
                , (err, res, body) =>
                    if err?
                        @emit('error', err)
                        console.log err
                    else
                        body = JSON.parse(body)
                        comments = new r.Comments body
                        activity = []
                        for comment in comments.comments
                            activity.push new UserActivity(
                                'reddit',
                                @c_url,
                                permalink,
                                comment.author,
                                comment.body,
                                comment.created_utc,
                                comment.ups
                            )
                        if activity.length
                            console.log "got back some activity: #{ activity }"
                            @emit('activity', activity)

                    completed_requests += 1
                    console.log completed_requests
                    console.log total_requests
                    if completed_requests == total_requests
                        @emit('done')
                )

        info_url = url.parse Reddit.base_url
        info_url.pathname = '/api/info.json'
        info_url.query = {'url': @c_url}
        request(
            uri: url.format(info_url)
            , (err, res, body) =>
                if err?
                    @emit('error', err)
                    console.log err
                else
                    body = JSON.parse body
                    i = new r.Info body
                    total_requests = i.permalinks.length
                    for permalink in i.permalinks
                        get_activity(permalink)
            )

exports.Reddit = Reddit
