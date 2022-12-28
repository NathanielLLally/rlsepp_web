"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
Object.defineProperty(exports, "ACK", {
  enumerable: true,
  get: function () {
    return _Instruction.ACK;
  }
});
Object.defineProperty(exports, "SYN", {
  enumerable: true,
  get: function () {
    return _Instruction.SYN;
  }
});
Object.defineProperty(exports, "SYN_ACK", {
  enumerable: true,
  get: function () {
    return _Instruction.SYN_ACK;
  }
});
exports.default = void 0;

var _Instruction = require("./Instruction.mjs");

var _EventEmitter = _interopRequireDefault(require("./EventEmitter.js"));

var _Message = _interopRequireDefault(require("./Message.mjs"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

class Protocol extends _EventEmitter.default {
  constructor(ws, options) {
    super();

    _defineProperty(this, "internal", new _EventEmitter.default());

    this.ws = ws;
    this.options = options;
  }

  read(encoded) {
    const message = _Message.default.from(encoded, this.options);

    message.client = this;

    message.reply = (...args) => {
      const replyMessage = message.makeReply(...args);
      return this.send(replyMessage);
    };

    const {
      instruction,
      id
    } = message;

    if (instruction instanceof _Instruction.SYN) {
      const {
        command,
        args
      } = instruction;
      this.emit(command, message, ...args);
      this.emit("message", command, message, ...args);
    }

    if (instruction instanceof _Instruction.ACK || instruction instanceof _Instruction.SYN_ACK) {
      this.internal.emit(id, message);
    }

    return message;
  }

  send(message) {
    return new Promise(resolve => {
      const {
        id
      } = message;
      this.internal.once(id, reply => {
        const {
          instruction
        } = reply;
        const {
          args
        } = instruction;
        resolve([reply, ...args]);
      });
      this.ws.send(message.encode());
    });
  }

}

exports.default = Protocol;