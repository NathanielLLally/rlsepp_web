

import Client from "/js/ws-promise/Client.mjs"

export default class awsRPC {
  constructor(opts) {
		this.ws = null;
    this.url = 'wss://skyhawk.grandstreet.group:2324/';
    if (opts.url) {
      this.url = opts.url
    }
	}
	async connect() {
	  this.ws = new Client(this.url);
	  await this.ws.open();
		console.log('rpc.esm.js wss://connected');
//		$('.log').append('rpc.esm.js wss://connected<br/>');
	}

	async RPC(Pjson) {

    if (!this.ws.connected) {
      await this.connect();
    }
  let r = null;
    if (Pjson.cmd) {
      try {
        r = await this.client[Pjson.cmd](Pjson);                                                                
        console.log(r);                                                                                        
        return r;
      } catch(e) {
        console.log(Pjson);                                                                                    
        console.log(e);                                                                                        
      }                                                                                                        
    }
    return r;                                                                                                  
  }   	
}
