var TimelineImage = Backbone.Model.extend({
    defaults: {
        imageLoaded: false,
        rotation: 0
    },
    initialize: function() {
        this.set('originalImage', new Image());
    },
    setSrc: function(src, nfo) {
        var self = this;
        $(this.get('originalImage')).on('load', function(e) {
            self.set('imageLoaded', true);
            self.trigger('imageLoaded', self);
        });

        this.get('originalImage').src = src;
        this.get('originalImage').nfo = nfo;
    },
    getSrc: function() {
        return this.get('originalImage').src;
    }
});

var Timeline = Backbone.Collection.extend({
    noPersistence: new bnp.NoPersistence(),
    model: TimelineImage,
    comparator: function(timelineImage) {
        return timelineImage.get("sequence");
    },
    nextSequence: function() {
        return this.length;
    },
    addImage: function(image) {
        this.add(image);
        this.sort();
    },
    swapImages: function(firstImage, secondImage) {
        var firstRef = this.find(function(img) { return img.get('originalImage').src === firstImage.src; });
        var secondRef = this.find(function(img) { return img.get('originalImage').src === secondImage.src; });

        var seq = firstRef.get('sequence');
        firstRef.set('sequence', secondRef.get('sequence'));
        secondRef.set('sequence', seq);

        this.sort();
    },
    removeImage: function(image) {
      this.remove(image);
      this.sort();
    },
});

var MFAApp = Backbone.Model.extend({
    defaults: {
       animatedGIF: null
    },
    initialize: function() {
        this.set('timeline', new Timeline());
    },
    restart: function() {
        this.get('timeline').reset();
        this.get('timeline').trigger('restart');

        this.set(this.defaults);
//        this.get('settings').reset();

        this.trigger('restart');
    },
    getRawImages: function() {
        return this.get('timeline').map(function(timelineImage) { return timelineImage.get('originalImage'); });
    },
    swapImages: function(firstImage, secondImage) {
        this.get('timeline').swapImages(firstImage, secondImage);
    },
    uploadImages: function() {
       console.log('http://'+location.hostname+'/upload');
       var tl = this.get('timeline');
      this.get('timeline').map(function(img) {
      
      console.log(img.filename);
      var req = $.ajax({
        url: 'http://'+location.hostname+'/upload.json',
        type: 'POST',
        data: {
          size: img.get('originalImage').nfo.size,
          prettySize: img.get('originalImage').nfo.extra.prettySize,
          modifiedDate: img.get('originalImage').nfo.lastModifiedDate,
          type: img.get('originalImage').nfo.type,
          name: img.get('originalImage').nfo.name,
          src: img.get('originalImage').src,
        },
        dataType: 'json'
      }).done(function(response, textStatus, jqXHR) {
        if (response.error) {
          alert(response.error);
        } else {

          console.log('success!');
          tl.removeImage(img);
//          document.location = "/images";
        }
      }).fail(function(response, textStatus, errorThrown) {
        console.error('yaaar, some ajax error'+textStatus, errorThrown);
      });
    
      });

      tl.trigger('change', 'remove');
    },
  });

// constants
MFAApp.MAX_BYTES = 3*1024*1024; // 2MB
