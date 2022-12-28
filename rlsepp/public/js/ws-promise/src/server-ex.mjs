import Server from "./Server";
class MathServer extends Server {
  constructor() {
    super({
engineOptions: {
port: 8080
}
});
}
async onAdd(message, ...args) {
  /* Clients can sum up numbers on the server */
  await message.reply(args.reduce((a, b) => a + b));
  /* In this line, the client will have received the result! */
}
}
const server = new MathServer();
server.open();
