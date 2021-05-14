var SubmitButtonView = Backbone.View.extend({
    events: {
        'click': 'uploadImages'
    },
    uploadImages: function(e) {
        this.model.uploadImages();
        return false;
    }
});

var ResetButtonView = Backbone.View.extend({
    events: {
        'click': 'clearTimeline'
    },
    clearTimeline: function(e) {
        this.model.restart();

        return false;
    }
});

var ShareButtonView = Backbone.View.extend({
    events: {
        'click': 'shareAnimation',
    },
    initialize: function() {
        this.model.on('animationGenerated', this.showShareLink, this);
        this.model.on('restart', this.hideShareLink, this);
    },
    showShareLink: function(animatedGIF) {
        if(animatedGIF) {
            this.$el.show();
        }
    },
    shareAnimation: function(e) {
        var filename = "animated."+((+new Date()) + "").substr(8);

        // Imgur takes the image data, filename, title, caption, success callback and error callback
        ShareGIFWith.imgur(this.model.getAnimatedGIF().rawDataURL(), filename, '', '', 
        function(deletePage, imgurPage, largeThumbnail, original, smallSquare) {
            prompt('Boom! Your image is now available on imgur. Copy the link below:', imgurPage);
        }, 
        function() {
            alert('Could not upload image to imgur. :/  Sorry.');
        });

        return false;
    },
    hideShareLink: function() {
        this.$el.hide();
    }
});

var DownloadButtonView = Backbone.View.extend({
    initialize: function() {
        this.model.on('animationGenerated', this.showDownloadLink, this);
        this.model.on('restart', this.hideDownloadLink, this);
    },
    showDownloadLink: function(animatedGIF) {
        if(animatedGIF) {
            window.URL = window.webkitURL || window.URL;
            window.BlobBuilder = window.BlobBuilder || window.WebKitBlobBuilder || window.MozBlobBuilder;

            var filename = "animated."+((+new Date()) + "").substr(8);

            var downloadLink = this.$el;
            downloadLink.hide();

            if(Modernizr.download && Modernizr.bloburls && Modernizr.blobbuilder) {
                downloadLink.attr('download', filename + '.gif');
                downloadLink.attr('href', animatedGIF.binaryURL(filename));
                downloadLink.show();

                downloadLink.on('click', function(e) {
                  // Need a small delay for the revokeObjectURL to work properly.
                  setTimeout(function() {
                    window.URL.revokeObjectURL(downloadLink.href);
                  }, 1500);
                });
            } else {
                window.onmessage = function(e) {
                    e = e || window.event;

                    var origin = e.origin || e.domain || e.uri;
                    if(origin !== "http://saveasbro.com") return;
                    downloadLink.attr('href', e.data);
                    downloadLink.show();
                };

                var iframe = document.querySelector('#saveasbro');
                iframe.contentWindow.postMessage(JSON.stringify({name:filename, data: animatedGIF.rawDataURL(), formdata: Modernizr.formdata}),"http://saveasbro.com/gif/");
            }
        }
    },
    hideDownloadLink: function() {
        this.$el.hide();
    }
});

var ResultsView = Backbone.View.extend({
    initialize: function() {
        this.submitButtonView = new SubmitButtonView({model: this.model, el: this.$el.find('.play')});
        this.resetButtonView = new ResetButtonView({model: this.model, el: this.$el.find('.clear')});
        this.downloadButtonView = new DownloadButtonView({model: this.model, el: this.$el.find('#downloadlink')});
        this.shareButtonView = new ShareButtonView({model: this.model, el: this.$el.find('#sharelink')});

//        this.animatedGIFView = new AnimatedGIFView({model: this.model, el: this.$el.find('#animresult')});
    }
});

var TimelineImageView = Backbone.View.extend({
    tagName: 'div',
    tagClass: 'col',
    events: {
        'click': 'remove'
    },
    initialize: function() {
        this.model.bind('destroy', this.remove, this);
    },
    render: function() {
        this.$el.html("<div class='col'><img class='removeimg' src='" + this.model.getSrc() + "' /><div class='fil3l'></div></div>");
        return this;
    }
});

var TimelineView = Backbone.View.extend({
    events: {
        'filedropsuccess': 'insertFile',
        'filedroperror': 'fileError',

        'dragstart .col': 'dragStart',
        'dragenter .col': 'dragEnter',
        'dragover .col': 'dragOver',
        'dragleave .col': 'dragLeave',
        'drop .col': 'drop',
        'dragend .col': 'dragEnd',
    },
    initialize: function() {
        this.model.on('restart', this.restartTimeline, this);
        this.model.on('change', this.doIt, this);
    },
    doIt: function(arg) {
      if (arg == 'remove') {
//        alert('doinIt');
//        this.model.reset();
        this.$el.empty();
      }
    },
    restartTimeline: function() {
        this.$el.empty();
    },
    insertFile: function(e, fileData, fileInfo) {
        var timelineImage = new TimelineImage({sequence:this.model.nextSequence()});
        timelineImage.setSrc(fileData,fileInfo);
        this.model.addImage(timelineImage);

        var timelineImageView = new TimelineImageView({model: timelineImage});
        this.$el.append(timelineImageView.render().el);
    },
    fileError: function(e, fileInfo) {
        this.$el.append("<div class='col error'>Error<div class='fil3l'></div></div>");
    },
    dragStart: function(e) {
        this.dragSrcEl_ = $(e.currentTarget);

        e.originalEvent.dataTransfer.effectAllowed = 'move';
        e.originalEvent.dataTransfer.setData('text/html', this.dragSrcEl_.html());

        this.dragSrcEl_.addClass('moving');
    },
    dragOver: function(e) {
        if (e.originalEvent.preventDefault) {
            e.originalEvent.preventDefault(); // Allows us to drop.
        }
        e.originalEvent.dataTransfer.dropEffect = 'move';
    },
    dragEnter: function(e) {
        $(e.currentTarget).addClass('over');
    },
    dragLeave: function(e) {
        $(e.currentTarget).removeClass('over'); // this/e.target is previous target element.
    },
    drop: function(e) {
        if (e.originalEvent.stopPropagation) {
            e.originalEvent.stopPropagation(); // stops the browser from redirecting.
        }
        if (e.originalEvent.preventDefault) {
            e.originalEvent.preventDefault(); // Allows us to drop.
        }
    
        var dropTarget = $(e.currentTarget);
        var swapTarget = this.dragSrcEl_;

        if (dropTarget.hasClass('col') && this.dragSrcEl_.html() != dropTarget.html()) {
           swapTarget.html(dropTarget.html());
           dropTarget.html(e.originalEvent.dataTransfer.getData('text/html'));

           this.model.swapImages(swapTarget.children().first().get(0), dropTarget.children().first().get(0));

           this.dragEnd(null);
        }
    },
    dragEnd: function(e) {
        this.$el.find('.col').removeClass('over moving');
        $('body').removeClass('drag'); // todo not sure what is adding this class to the body but it causes problems if it isn't removed
    }
});


var MFAAppView = Backbone.View.extend({
    el: 'div#container',
    initialize: function() {
        this.model.on('restart', this.restartView, this);
        this.model.get('timeline').on('add', this.imageAdded, this);

        this.timelineView = new TimelineView({model: this.model.get('timeline'), el: this.$el.find('div#inimglist')});
        this.resultsView = new ResultsView({model: this.model, el: this.$el.find('#results')});
    },
    restartView: function() {
        $("body").removeClass("hasfiles");
    },
    imageAdded: function() {
        $("body").addClass("hasfiles");
    }
});
