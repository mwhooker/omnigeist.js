request = require 'request'
r = require './reddit'
url = require 'url'
util = require 'util'
events = require 'events'


class UserActivity
    constructor: (@host, @link, @permalink, @username, @comment, @timestamp, @rank, @others...) ->

class HackerNews extends events.EventEmitter
    @base_url = 'http://api.ihackernews.com'
    @host_url = 'http://news.ycombinator.com'

    permalink: (id) ->
        permalink = url.parse(HackerNews.host_url)
        permalink.path = 'item'
        permalink.query = {id: id}
        return url.format(permalink)

    constructor: (@c_url) ->

    fetch: () ->

        get_activity = (item_id) =>
            activity_url = url.parse HackerNews.base_url
            activity_url.pathname =  'post/' + item_id
            console.log "requesting activity from #{ url.format activity_url }"
            request(
                uri: url.format(activity_url)
                , (err, res, body) =>
                    if err?
                        console.log err
                        @emit('error', err)
                    else
                        body = JSON.parse(body)
                        activity = []
                        for comment in body.comments
                            activity.push new UserActivity(
                                'hacker news',
                                @c_url,
                                this.permalink(item_id),
                                comment.postedBy,
                                comment.comment,
                                comment.postedAgo,
                                comment.points
                            )
                        if activity.length
                            console.log "got back some activity: #{ activity }"
                            @emit('activity', activity)

                )

        id_url = url.parse HackerNews.base_url
        id_url.pathname =  'getid'
        id_url.query = {url: @c_url}
        request(
            uri: url.format(id_url)
            , (err, res, body) =>
                if err?
                    console.log err
                    @emit('error', err)
                else
                    body = JSON.parse body
                    for id in body
                        get_activity(id)
            )



class Reddit extends events.EventEmitter

    @base_url = 'http://www.reddit.com'

    constructor: (@c_url) ->

    fetch: () ->


        get_activity = (permalink) =>
            console.log "requesting activity from #{ permalink }"
            activity_url = url.parse Reddit.base_url
            activity_url.pathname = permalink + '.json'
            request(
                uri: url.format(activity_url)
                , (err, res, body) =>
                    if err?
                        console.log err
                        @emit('error', err)
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
                                comment.body_html,
                                comment.created_utc,
                                comment.ups
                            )
                        if activity.length
                            console.log "got back some activity: #{ activity }"
                            @emit('activity', activity)

                )

        info_url = url.parse Reddit.base_url
        info_url.pathname = '/api/info.json'
        info_url.query = {'url': @c_url}
        request(
            uri: url.format(info_url)
            , (err, res, body) =>
                if err?
                    console.log err
                    @emit('error', err)
                else
                    body = JSON.parse body
                    i = new r.Info body
                    for permalink in i.permalinks
                        get_activity(permalink)
            )

exports.Reddit = Reddit
exports.HackerNews = HackerNews
