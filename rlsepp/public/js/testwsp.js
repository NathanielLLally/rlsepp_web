const Client = require "ws-promise.js";
const client = new Client("ws://localhost:8000");
(async () => {
	await client.open();
	/* The client can now call all server (!) methods that you expose */
	const six = await client.add(1, 2, 3);
	console.log(six);
})();
