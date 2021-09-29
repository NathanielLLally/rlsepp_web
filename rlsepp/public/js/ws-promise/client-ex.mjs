import Client from "./Client.mjs";
const client = new Client("wss://localhost:2324");

(async () => {
  await client.open();
  const six = await client.add(1, 2, 3);
  console.log(six);
})();
