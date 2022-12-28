"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

class RemoteError extends Error {
  constructor(message, remoteStack) {
    super(message);
    this.remoteStack = remoteStack;
  }

}

exports.default = RemoteError;