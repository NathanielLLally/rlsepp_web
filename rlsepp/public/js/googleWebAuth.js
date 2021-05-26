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
function setUser(token, val) {
//  var key = '_'+api+'user'+token;
  var key = token

  var opts = { domain: '.grandstreet.group' };
  Cookies.set(key, val, opts);
}

//see console within browser for execution
function onSignIn(googleUser) {
  var idToken;
  var profile;
      profile = googleUser.getBasicProfile();
      idToken = googleUser.getAuthResponse().id_token;

  setUser('_guserid', profile.getId())
  setUser('_gusername', profile.getName())
  setUser('_guserimageurl', profile.getImageUrl())
  setUser('_guseremail', profile.getEmail())
  setUser('_useremail', profile.getEmail())

  setUser('_jssesh', btoa(JSON.stringify(['_useremail', '_guserid', '_guseremail', '_gusername', '_guserimageurl'])))

/*
      console.log('ID: ' + profile.getId());
      console.log('Full Name: ' + profile.getName());
      console.log('Given Name: ' + profile.getGivenName());
      console.log('Family Name: ' + profile.getFamilyName());
      console.log('Image URL: ' + profile.getImageUrl());
      console.log('Email: ' + profile.getEmail());
      */

      $('a#login_href').attr('href','/app/portal');
      $('a#login_href').html('You may enter our portal');

      console.log(document.cookie)

      $('.useremail').html(getUser('email', 'g'));
      $('.useroauth').html("<pre><p>"+getUser('name', 'g')+"<img src=\""+getUser('imageurl','g')+"\"/></pre>");
}

function onSignOut(){
      var gapi = $(window.gapi);
      var auth2 = gapi.auth2.getAuthInstance();
          auth2.signOut();
      guser.isSignedIn =false;
}

  // Wait until the DOM has loaded before querying the document
    //document.cookie = "testCookie=cookieval; domain=." + 
  $(document).ready(function() {
    location.hostname.split('.').reverse()[1] + "." + 
    location.hostname.split('.').reverse()[0] + "; path=/"

    
//    $('#login_uid').html("<pre><p> Hello "+getUser('name', 'g')+"<img src=\""+getUser('imageurl','g')+"\"/></pre>");
      $('a#test_href').html('bam');
     // (function(e) { 
     //   console.log(gapi); 
      //  }); 

      });
