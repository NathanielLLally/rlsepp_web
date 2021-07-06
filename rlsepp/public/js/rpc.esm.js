import { default as WebSocketClient } from "/js/websocket-async.esm.js"

export default class awsRPC {
  constructor() {
		this.ws = null;
	}
	async connect() {
	  this.ws = new WebSocketClient;
	  await this.ws.connect('wss://skyhawk.grandstreet.group:2324/');
		console.log('rpc.esm.js wss://connected');
//		$('.log').append('rpc.esm.js wss://connected<br/>');
	}

	async RPC(Pjson) {

    if (!this.ws.connected) {
      await this.connect();
    }
		if (Pjson) {
			this.ws.send(JSON.stringify(Pjson));
		}
		let data = JSON.parse( await this.ws.receive() );

		if (this.ws.dataAvailable !== 0) {
			data = {
				...data,
				...JSON.parse(await this.ws.receive())
			}
		}
//		$('.log').append(`${JSON.stringify(data,null,2)}<br/>`);
		// Close the connection.
		//  await ws.disconnect();
		return data;
	}
	

}
