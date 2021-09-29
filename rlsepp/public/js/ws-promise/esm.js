"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _default = (module, key = "default") => {
  return process.env.NODE_ENV === "test" ? module : module[key] || module;
};

exports.default = _default;