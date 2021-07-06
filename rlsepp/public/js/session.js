//  https://stackoverflow.com/questions/49077585/how-to-use-es6-import-client-side-js
//  import is only globally supported by Node
$.getScript( '/js/websocket-as-promised/src/index.js' )
.done(function( script, textStatus ) {
    console.log( textStatus );
})
.fail(function( jqxhr, settings, exception ) {
    $( "div.log" ).text( "Triggered ajaxError handler." );
});


function wsSession_get(key, cb) {
  console.log('wsSession(key), ['+key+']');
  return wsSession(key, null);
}

function wsSession(key,value, cb) {
  console.log('wsSession(key, value), ['+key+']['+value+']');
  if (!("WebSocket" in window)) {
    alert('Your browser does not support WebSockets!');
    return;
  }

  var ws = new WebSocket("<%= $socket %>");
  ws.onopen = function () {
    var json = {
      sid: Cookies.get('sid'),
    };
    json[key] = value;

    console.log(json)
    ws.send(JSON.stringify(json));
  };
  ws.onmessage = function (evt) {
    console.log('wsSession on message');
    var data = JSON.parse(evt.data);
    cb(data);
  };
  ws.onerror = function(err) {
    console.log(err);
  };
}

