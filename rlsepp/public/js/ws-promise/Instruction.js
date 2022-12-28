"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.SYN_ACK = exports.ACK = exports.SYN = void 0;

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

class Instruction {
  constructor(command, ...args) {
    this.args = args;
    this.command = command;
    this.type = this.constructor.type;

    for (let i = 0; i < args.length; ++i) {
      const arg = args[i];

      if (arg instanceof Error) {
        args[i] = {
          error: true,
          message: arg.message,
          stack: arg.stack
        };
      }
    }
  }

}

class SYN extends Instruction {}

exports.SYN = SYN;

_defineProperty(SYN, "type", 0);

class ACK extends Instruction {}

exports.ACK = ACK;

_defineProperty(ACK, "type", 1);

class SYN_ACK extends Instruction {}

exports.SYN_ACK = SYN_ACK;

_defineProperty(SYN_ACK, "type", 2);