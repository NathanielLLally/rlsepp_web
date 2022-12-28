"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _ws = _interopRequireDefault(require("ws"));

var _crystalEventEmitter = _interopRequireDefault(require("crystal-event-emitter"));

var _Protocol = _interopRequireDefault(require("./Protocol"));

var _addDefaults = _interopRequireDefault(require("./addDefaults"));

var _proxify = _interopRequireDefault(require("./proxify"));

var _esm = _interopRequireDefault(require("./esm"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _classPrivateFieldGet(receiver, privateMap) { var descriptor = _classExtractFieldDescriptor(receiver, privateMap, "get"); return _classApplyDescriptorGet(receiver, descriptor); }

function _classApplyDescriptorGet(receiver, descriptor) { if (descriptor.get) { return descriptor.get.call(receiver); } return descriptor.value; }

function _classPrivateFieldSet(receiver, privateMap, value) { var descriptor = _classExtractFieldDescriptor(receiver, privateMap, "set"); _classApplyDescriptorSet(receiver, descriptor, value); return value; }

function _classExtractFieldDescriptor(receiver, privateMap, action) { if (!privateMap.has(receiver)) { throw new TypeError("attempted to " + action + " private field on non-instance"); } return privateMap.get(receiver); }

function _classApplyDescriptorSet(receiver, descriptor, value) { if (descriptor.set) { descriptor.set.call(receiver, value); } else { if (!descriptor.writable) { throw new TypeError("attempted to set read only private field"); } descriptor.value = value; } }

const EventEmitter = (0, _esm.default)(_crystalEventEmitter.default);
const WebSocketServer = (0, _esm.default)(_ws.default, "Server");

var _wss = new WeakMap();

class Server extends EventEmitter {
  constructor(options = {}) {
    super({
      inferListeners: true
    });

    _defineProperty(this, "clients", new Set());

    _defineProperty(this, "options", null);

    _wss.set(this, {
      writable: true,
      value: null
    });

    this.options = (0, _addDefaults.default)(options, {
      engine: WebSocketServer
    });
  }

  async broadcast(message) {
    const replies = new Map();

    for (const client of this.clients) {
      const clientMessage = await client.send(message);
      replies.set(client, clientMessage);
    }

    return replies;
  }

  clear() {
    this.clients.clear();

    _classPrivateFieldSet(this, _wss, null);
  }

  open() {
    return new Promise(resolve => {
      _classPrivateFieldSet(this, _wss, new this.options.engine(this.options.engineOptions));

      _classPrivateFieldGet(this, _wss).on("listening", () => {
        resolve(this);
      });

      _classPrivateFieldGet(this, _wss).on("connection", (ws, request) => {
        const client = (0, _proxify.default)(new _Protocol.default(ws, this.options), Object.assign({}, this.options));
        client.request = request;

        client.close = () => new Promise(resolve => {
          ws.on("close", () => {
            resolve(this);
          });
          ws.close();
        });

        this.clients.add(client);
        this.emit("connection", client);
        ws.on("message", encoded => client.read(encoded));
        ws.on("close", e => {
          this.clients.delete(client);
          client.emit("close");
          this.emit("clientClose", client, e);
        });
        client.on("*", (event, ...args) => {
          if (event !== "close") {
            this.emit(...args);
          }
        });
      });
    });
  }

  close() {
    return new Promise((resolve, reject) => {
      if (!_classPrivateFieldGet(this, _wss)) {
        resolve(this);
        return;
      }

      _classPrivateFieldGet(this, _wss).close(error => {
        if (error) {
          reject(error);
        } else {
          resolve(this);
          this.clear();
        }
      });
    });
  }

}

exports.default = Server;