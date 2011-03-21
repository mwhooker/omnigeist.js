fs = require 'fs'
debug = require('util').debug
reddit = require "../lib/reddit"
fixtures_dir = __dirname + '/fixtures/reddit'

class TestListener

    constructor: () ->
        @failures = {}
        @tests_failed = false

    on_failure: (event) =>
        @tests_failed = true
        target = event.target
        @failures[event.target.name] ?= {
            target: target
            events: []
        }
        @failures[target.name].events.push event

    summarize: =>
        debug if @tests_failed then "Tests failed!" else "Tests Passed!"
        for test, {target, events} of @failures
            debug "#{ target.failures } failures in \"#{ test }\""
            for event in events
                debug "  #{ event.message }"
                debug "    expected: #{ event.expected}"
                debug "    got:      #{ event.actual }"


Spec = require('spec').Spec
spec = new Spec('Test Reddit')
listener = new TestListener

spec.addTest('test info', (test) ->
    data = ['/r/javascript/comments/er5m9/coffeescript_10_released/',
            '/r/webdev/comments/ebqgy/coffeescript_a_cleaner_javascript/',
            '/r/web_design/comments/e1or8/coffeescript_is_a_little_language_that_compiles/',
            '/r/Lusitania/comments/azlht/coffeescript/',
            '/r/coding/comments/alm5b/coffeescript_a_little_language_that_compiles_to/',
            '/r/programming/comments/ai9kk/coffeescript_a_little_language_that_compiles_to/']
    fs.readFile(fixtures_dir + '/info.json', (err, data) ->
        throw err if err
        fixture = new reddit.Info JSON.parse data
        test.deepEqual(data, fixture.permalinks, 'permalink parsing works')
        test.done()
    )
)
spec.on('failure', listener.on_failure)
spec.run()

listener.summarize()
