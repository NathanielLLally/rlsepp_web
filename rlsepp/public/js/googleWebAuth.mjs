var guser = {
  id: 0,
  name: "",
  imageurl: "",
  email: "",
  isSignedIn: false,
  };

function setSession(token, val) {
  Cookies.set('_'+token, val);
}

function getSession(token) {

}

//  TODO: robustify
//  
//  getUser(id|name|imageurl|email, g|f|i)
//
function getUser(token, api) {
  var key = '_'+api+'user'+token;
  var val =  Cookies.get(key);
  if (val) return val;
  return null;
}
function getCookie(token) {
  var val =  Cookies.get(token);
  if (val) return val;
  return null;
}
function setCookie(token, val) {
  setUser(token,val);
}
function setUser(token, val) {
//  var key = '_'+api+'user'+token;
  var key = token

  var opts = { domain: '.grandstreet.group', samesite: 'Lax' };
  Cookies.set(key, val, opts);
}

function wsSession(json) {

  console.table(json);
  if (!("WebSocket" in window)) {
    alert('Your browser does not support WebSockets!');
    return;
  }

  var ws = new WebSocket("ws://portal.grandstreet.group/session");
  ws.onopen = function () {
    console.log(json)
    ws.send(JSON.stringify(json));
  };
  ws.onmessage = function (evt) {
    console.log('wsSession on message');
    var data = JSON.parse(evt.data);
		console.table(data);
    setCookie('sid', data.sid);
  };
}
/**
 * An asynchronous WebSocket client.
 * @example
 * // Set up connection.
 * const webSocketClient = new WebSocketClient;
 * // Connect.
 * await webSocketClient.connect('ws://www.example.com/');
 * // Send is synchronous.
 * webSocketClient.send('Hello!');
 * // Receive is asynchronous.
 * console.log(await webSocketClient.receive());
 * // See if there are any more messages received.
 * if (webSocketClient.dataAvailable !== 0) {
 *     console.log(await webSocketClient.receive());
 * } 
 * // Close the connection.
 * await webSocketClient.disconnect();
 */

async function wsSession_async(json) {
  const webSocketClient = new WebSocketClient;
  await webSocketClient.connect('ws://portal.grandstreet.group/session');
  webSocketClient.send(JSON.stringify(json));
  console.log(await webSocketClient.receive());
  if (webSocketClient.dataAvailable !== 0) {
    console.log(await webSocketClient.receive());
	}
  await webSocketClient.disconnect();
}

//see console within browser for execution
async function onSignIn(googleUser) {
  var idToken;
  var profile;
      profile = googleUser.getBasicProfile();
      idToken = googleUser.getAuthResponse().id_token;

	let sid = getCookie('sid');
	console.log('cookie sid :'+sid);


	let json = {
		guserid: profile.getId(),
	  gusername: profile.getName(),
	  guserimageurl: profile.getImageUrl(),
	  guseremail: profile.getEmail(),
	  useremail: profile.getEmail(),
	};
	await wsSession_async(json);

/*
      console.log('ID: ' + profile.getId());
      console.log('Full Name: ' + profile.getName());
      console.log('Given Name: ' + profile.getGivenName());
      console.log('Family Name: ' + profile.getFamilyName());
      console.log('Image URL: ' + profile.getImageUrl());
      console.log('Email: ' + profile.getEmail());
      */

//      $('a#portal_href').attr('href','/app/portal');
//      $('a#login_href').attr('href','/app/portal');
//      $('a#login_href').html('You may enter our portal');
//
      console.log(document.cookie)

//      $('.useremail').html(getUser('email', 'g'));
//      $('.useroauth').html("<pre><p>"+getUser('name', 'g')+"<img src=\""+getUser('imageurl','g')+"\"/></pre>");
}

function onSignOut(){
      var gapi = $(window.gapi);
      var auth2 = gapi.auth2.getAuthInstance();
          auth2.signOut();
      guser.isSignedIn =false;
}

