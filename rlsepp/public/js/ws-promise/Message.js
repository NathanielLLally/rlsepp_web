"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _Instruction = require("./Instruction.mjs");

function uuid() {
  const url = URL.createObjectURL(new Blob());
  const [id] = url.toString().split('/').reverse();
  URL.revokeObjectURL(url);
  return id;
}

class Message {
  constructor(instruction, options, id = uuid()) {
    this.id = id;
    this.instruction = instruction;
    this.options = options;
  }

  makeReply(...args) {
    let nextInstruction;
    const {
      instruction,
      options,
      id
    } = this;

    if (instruction instanceof _Instruction.SYN) {
      nextInstruction = _Instruction.ACK;
    } else if (instruction instanceof _Instruction.ACK) {
      nextInstruction = _Instruction.SYN_ACK;
    } else {
      throw new Error("Invalid attempt to reply to a reply");
    }

    return new Message(new nextInstruction(instruction.command, ...args), options, id);
  }

  encode() {
    return this.options.encode({
      id: this.id,
      instruction: this.instruction
    });
  }

  static from(encoded, options) {
    let preprocessed = encoded;

    if (encoded instanceof ArrayBuffer) {
      preprocessed = new Uint8Array(encoded);
    }

    const object = options.decode(preprocessed);
    const {
      args,
      command,
      type
    } = object.instruction;
    const [constructor] = [_Instruction.SYN, _Instruction.ACK, _Instruction.SYN_ACK].filter(c => c.type === type);
    const instruction = new constructor(command, ...args);
    return new this(instruction, options, object.id);
  }

}

exports.default = Message;