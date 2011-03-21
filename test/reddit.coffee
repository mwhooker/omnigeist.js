debug = require('util').debug

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
        debug "Tests failed!" if @tests_failed
        for test, {target, events} of @failures
            debug "#{ target.failures } failures in \"#{ test }\""
            for event in events
                debug "  #{ event.message }"
                debug "    expected: #{ event.expected}"
                debug "    got:      #{ event.actual }"


test_listener = (event) ->
    console.log event
    debug(event.message)


Spec = require('spec').Spec
spec = new Spec('Sample Spec')
listener = new TestListener

spec.addTest('tests', (test) ->
    test.equal(4, 's', 'damn')
    test.ok(4 == 5, 'doh')
    test.done()
)
spec.on('failure', listener.on_failure)
spec.run()

listener.summarize()
