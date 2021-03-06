/*
 * TODO:
 *  check if jquery is on the page already
 */
(function() {
  var ogHost = window.ogHost;
  var ogPort = window.ogPort || 80;
  var og = window.og;
  var config = {
    height: 150,
    width: 700
  };
  _jq_script=document.createElement('script');
  _jq_script.type='text/javascript';
  _jq_script.src=ogHost + '/js/jquery-1.5.1.min.js';
  document.documentElement.appendChild(_jq_script);

  var jqueryLoaded = function(callback) {
    tryReady = function(timeElapsed) {
      // Continually polls to see if jQuery is loaded.
      if (typeof jQuery == "undefined") { // if jQuery isn't loaded yet...
        if (timeElapsed <= 5000) {
          setTimeout("tryReady(" + (timeElapsed + 200) + ")", 200);
        } else {
          alert("Timed out while loading jQuery.")
        }
      } else {
        // jQuery loaded successfully
        jQuery.noConflict();
        callback();
      }
    }
    return tryReady(0);
  }

  var currentUrl = window.location.href;

  var loadScripts = function(scripts, success, failure) {
    var count = 0;
    for (var i in scripts) {
      jQuery.getScript(scripts[i], function() {
        count += 1;
        if (count == scripts.length) {
          success();
        }
      });
    }
  }

  var main = function() {
    Hyphenator.config({
      defaultlanguage: 'en',
      minwordlength: 4,
      remoteloading: true,
      enablecache: false,
      onerrorhandler: function(error) {
        console.log(error);
      },
      selectorfunction: function () {
        return jQuery('#og-comments .comment-content').get();
      }
    });
    //Hyphenator.run();

    var commentTpl = window.og['commentTpl'];
    var omnigeistTpl = window.og['omnigeistTpl'];

    window.og.Comment = Backbone.Model.extend({
    });

    window.og.CommentList = Backbone.Collection.extend({
      model: window.og.Comment,
      comparator: function(comment) {
        return comment.get('rank');
      }
    });

    window.og.CommentView = Backbone.View.extend({
      tagName: 'li',

      template: _.template(commentTpl),

      initialize: function() {
        _.bindAll(this, 'render');
        this.model.bind('change', this.render);
        this.model.view = this;
      },

      render: function() {
        jQuery(this.el).html(this.template(this.model.toJSON()));
        return this;
      }
    });

    var comments = window.og.comments = new window.og.CommentList;

    window.og.Omnigeist = Backbone.View.extend({
      el: jQuery('#omnigeist'),

      initialize: function() {
        _.bindAll(this, 'addOne', 'addAll');

        comments.bind('add',     this.addOne);
        comments.bind('all',     this.render);

        jQuery('#og-close').click(function() {
          jQuery('#omnigeist').hide();
        });
      },

      addOne: function(comment) {
        var view = new window.og.CommentView({model: comment});
        jQuery('#og-comments ul').append(view.render().el);
      },

      addAll: function() {
        comments.each(this.addOne);
      },
    });

    jQuery('html').append(_.template(omnigeistTpl));
    window.og.App = new window.og.Omnigeist;

    var socket = new io.connect(ogHost);

    socket.on('connect', function(){
      socket.send(currentUrl);
    })
    socket.on('activity', function(data){
        var comment = new window.og.Comment(data);
        window.og.App.addOne(comment);
    })
  }

  jqueryLoaded(function() {
    //underscore is a prereq for backbone
    jQuery.getScript(ogHost + '/js/underscore-min.js', function() {
      loadScripts([
        ogHost + '/templates.js',
        ogHost + '/js/json2.js',
        ogHost + '/js/backbone.js',
        ogHost + '/js/Hyphenator.js',
        ogHost + '/socket.io/socket.io.js',
      ], main);
    });
  });
})();
