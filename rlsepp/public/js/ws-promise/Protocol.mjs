function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import { ACK, SYN, SYN_ACK } from "./Instruction.mjs";
import EventEmitter from "./EventEmitter.js";
import Message from "./Message.mjs";
export { ACK, SYN, SYN_ACK };
export default class Protocol extends EventEmitter {
  constructor(ws, options) {
    super();

    _defineProperty(this, "internal", new EventEmitter());

    this.ws = ws;
    this.options = options;
  }

  read(encoded) {
    const message = Message.from(encoded, this.options);
    message.client = this;

    message.reply = (...args) => {
      const replyMessage = message.makeReply(...args);
      return this.send(replyMessage);
    };

    const {
      instruction,
      id
    } = message;

    if (instruction instanceof SYN) {
      const {
        command,
        args
      } = instruction;
      this.emit(command, message, ...args);
      this.emit("message", command, message, ...args);
    }

    if (instruction instanceof ACK || instruction instanceof SYN_ACK) {
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