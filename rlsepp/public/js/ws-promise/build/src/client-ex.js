import Client from "./Client.mjs";
const client = new Client("ws://localhost:8080");
(async () => {
    await client.open();
    /* The client can now call all server (!) methods that you expose */
    const six = await client.add(1, 2, 3);
    console.log(six);
})();