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
    await message.reply(args.reduce((a, b) => a + b));
  }

}

const server = new MathServer();
server.open();