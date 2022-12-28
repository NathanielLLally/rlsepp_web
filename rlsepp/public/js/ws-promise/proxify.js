"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _Message = _interopRequireDefault(require("./Message.mjs"));

var _RemoteError = _interopRequireDefault(require("./RemoteError.mjs"));

var _Protocol = require("./Protocol.mjs");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var _default = (around, {
  encode,
  decode,
  bind = false
} = {}) => new Proxy(around, {
  get: (target, property, receiver) => {
    if (property === "inspect") {
      return () => {
        return target;
      };
    }

    if (property === "then") {
      return receiver;
    }

    const lookUp = target[property];

    if (!lookUp) {
      return async (...args) => {
        const remoteLookUp = new _Message.default(new _Protocol.SYN(property, ...args), {
          encode,
          decode
        });
        const [message, result] = await target.send(remoteLookUp);
        message.reply();

        if (result && result.error && result.message && result.stack) {
          throw new _RemoteError.default(result.message, result.stack);
        } else {
          return result;
        }
      };
    } else {
      if (bind && lookUp instanceof Function) {
        return lookUp.bind(target);
      } else {
        return lookUp;
      }
    }
  }
});

exports.default = _default;