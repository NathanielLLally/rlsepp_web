"use strict";

var _Client = _interopRequireDefault(require("./Client.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const client = new _Client.default("wss://localhost:2324");

(async () => {
  await client.open();
  const six = await client.add(1, 2, 3);
  console.log(six);
})();
