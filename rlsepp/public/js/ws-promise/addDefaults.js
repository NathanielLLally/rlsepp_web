"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;
const {
  encode,
  decode
} = msgpack;
const commonDefaults = {
  encode,
  decode
};

var _default = (options, specifics) => Object.assign({}, commonDefaults, specifics, options);

exports.default = _default;