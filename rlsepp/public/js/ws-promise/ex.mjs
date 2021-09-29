import Client from "./Client";
const client = new Client("ws://portal.grandstreet.group/session");

(async () => {
  await client.open();
  const six = await client.add(1, 2, 3);
  console.log(six);
})();