"use strict";

var _Server = _interopRequireDefault(require("./Server"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

class MathServer extends _Server.default {
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