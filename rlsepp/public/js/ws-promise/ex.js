"use strict";

var _Client = _interopRequireDefault(require("./Client"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const client = new _Client.default("ws://portal.grandstreet.group/session");

(async () => {
  await client.open();
  const six = await client.add(1, 2, 3);
  console.log(six);
})();