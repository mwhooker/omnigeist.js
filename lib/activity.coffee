request = require 'request'
r = require './reddit'
url = require 'url'
util = require 'util'
events = require 'events'
disqus = require 'disqus-client'


class UserActivity
    constructor: (@host, @link, @permalink, @username, @comment, @timestamp, @rank, @others...) ->

class HackerNews extends events.EventEmitter
    @base_url: 'http://api.ihackernews.com'
    @host_url: 'http://news.ycombinator.com'

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
                    if err? or res.statusCode >= 400
                        console.log err
                        @emit('error', err)
                    else
                        body = JSON.parse(body)
                        for comment in body.comments
                            activity = new UserActivity(
                                'hacker news',
                                @c_url,
                                this.permalink(item_id),
                                comment.postedBy,
                                comment.comment,
                                comment.postedAgo,
                                comment.points
                            )
                            @emit('activity', activity)
                        if body.comments.length
                            console.log "got back some activity"

                )

        id_url = url.parse HackerNews.base_url
        id_url.pathname =  'getid'
        id_url.query = {url: @c_url}
        request(
            uri: url.format(id_url)
            , (err, res, body) =>
                if err? or res.statusCode >= 400
                    console.log err
                    @emit('error', err)
                else
                    body = JSON.parse body
                    for id in body
                        get_activity(id)
            )



class Reddit extends events.EventEmitter

    @base_url:'http://www.reddit.com'

    constructor: (@c_url) ->

    fetch: () ->


        get_activity = (permalink) =>
            console.log "requesting activity from #{ permalink }"
            activity_url = url.parse Reddit.base_url
            activity_url.pathname = permalink + '.json'
            request(
                uri: url.format(activity_url)
                , (err, res, body) =>
                    if err? or res.statusCode >= 400
                        console.log err
                        @emit('error', err)
                    else
                        body = JSON.parse body
                        comments = new r.Comments body
                        for comment in comments.comments
                            activity = new UserActivity(
                                'reddit',
                                @c_url,
                                permalink,
                                comment.author,
                                comment.body_html,
                                comment.created_utc,
                                comment.ups
                            )
                            @emit('activity', activity)
                        if comments.comments.length
                            console.log "got back some activity"

                )

        info_url = url.parse Reddit.base_url
        info_url.pathname = '/api/info.json'
        info_url.query = {'url': @c_url}
        request(
            uri: url.format(info_url)
            , (err, res, body) =>
                if err? or res.statusCode >= 400
                    console.log err
                    @emit('error', err)
                else
                    body = JSON.parse body
                    i = new r.Info body
                    for permalink in i.permalinks
                        get_activity(permalink)
            )

class Digg extends events.EventEmitter
    @base_url: 'http://services.digg.com'

    constructor: (@c_url) ->

    fetch: () ->
        info_url = url.parse Digg.base_url
        info_url.pathname = '/2.0/story.getInfo'
        info_url.query = {'links': @c_url}
        request(
            uri: url.format(info_url)
            , (err, res, body) =>
                console.log(url.format(info_url))
                if err? or res.statusCode >= 400
                    console.log err
                    @emit('error', err)
                else
                    body = JSON.parse body
                    if body.status >= 400
                        console.log(body)
                        @emit('error', body.message)
                    else
                        for story in body.stories
                            get_activity(story.story_id, story.permalink)
            )

        get_activity = (story_id, permalink) =>
            console.log "requesting activity for #{ story_id }"
            activity_url = url.parse Digg.base_url
            activity_url.pathname = '/2.0/story.getComments'
            activity_url.query = {
                story_id: story_id
            }
            request(
                uri: url.format(activity_url)
                , (err, res, body) =>
                    if err? or res.statusCode >= 400
                        console.log err
                        @emit('error', err)
                    else
                        body = JSON.parse(body)
                        if body.status >= 400
                            console.log(body)
                            @emit('error', body.message)
                        else
                            for comment in body.comments
                                activity = new UserActivity(
                                    'digg',
                                    @c_url,
                                    permalink,
                                    comment.user.username,
                                    comment.text,
                                    comment.date_created,
                                    comment.up
                                )
                                @emit('activity', activity)
                            if body.comments.length
                                console.log "got back some activity"
                )


class Disqus extends events.EventEmitter

    constructor: (@c_url) ->
        @dq = disqus(
            "ToCu9OEXZhNZoAq3V7aDBvaYQ5gYDjBeZ25vNjLVSGIgshZGfjuNNg9Oq3HjFEnu",
            'json',
            '3.0',
            false
        )

    fetch: () ->
        @dq.call('posts', 'list', thread: "link:" + @c_url, (response) ->
            response.iter (value, key) =>
                activity = new UserActivity(
                    'disqus',
                    @c_url,
                    @c_url + "#disqus_thread",
                    value.author.username,
                    value.message,
                    null, #created
                    value.points
                )
        )


exports.Digg = Digg
exports.Reddit = Reddit
exports.HackerNews = HackerNews
exports.Disqus = Disqus

