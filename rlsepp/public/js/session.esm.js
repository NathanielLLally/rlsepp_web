import { default as WebSocketClient } from "/js/websocket-async.esm.js"

async function asyncWsSession(sid, Pjson) {

  const ws = new WebSocketClient;
  await ws.connect('wss://portal.grandstreet.group/session');
  console.log('session.esm.js wss://connected');

  let json = {sid: sid};
  if (Pjson) {
    console.log(Pjson);
    json = {
      ...json,
      ...Pjson
    };
  }
  ws.send(JSON.stringify(json));
  let data = JSON.parse( await ws.receive() );

  if (ws.dataAvailable !== 0) {
    data = {
      ...data,
      ...JSON.parse(await ws.receive())
    }
  }
  // Close the connection.
  await ws.disconnect();
  return data;
}

export default asyncWsSession;
