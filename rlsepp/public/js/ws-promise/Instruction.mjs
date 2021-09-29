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

export class SYN extends Instruction {}

_defineProperty(SYN, "type", 0);

export class ACK extends Instruction {}

_defineProperty(ACK, "type", 1);

export class SYN_ACK extends Instruction {}

_defineProperty(SYN_ACK, "type", 2);