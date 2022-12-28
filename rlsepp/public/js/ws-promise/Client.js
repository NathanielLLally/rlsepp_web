"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _addDefaults = _interopRequireDefault(require("./addDefaults.js"));

var _codes = require("./codes.js");

var _EventEmitter = _interopRequireDefault(require("./EventEmitter.js"));

var _Protocol = _interopRequireDefault(require("./Protocol.js"));

var _proxify = _interopRequireDefault(require("./proxify.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

export default class Client extends _EventEmitter.default {
  constructor(...args) {
    super({
      inferListeners: true
    });

    _defineProperty(this, "ws", null);

    _defineProperty(this, "network", null);

    _defineProperty(this, "reconnecting", false);

    _defineProperty(this, "options", {});

    if (!args.length) {
      throw new Error("No arguments provided");
    }

    const [url] = args;
    this.url = url;

    if (args.length === 2) {
      const [, arg2] = args;

      if (typeof arg2 === "object") {
        this.options = arg2;
        this.protocols = null;
      } else {
        this.protocols = arg2;
      }
    }

    if (args.length === 3) {
      const [, protocols, options = {}] = args;
      this.protocols = protocols;
      this.options = options;
    }

    this.options = (0, _addDefaults.default)(this.options, {
      autoReconnect: true,
      binaryType: "arraybuffer",
      engine: globalThis.WebSocket,
      reconnectionFactor: 1.15,
      reconnectionMinimum: 200
    });

    if (!this.options.engine) {
      throw new Error("No WebSocket client implementation found. If your environment doesn't natively support WebSockets, please provide the client class to use with the `engine` option.");
    }

    this.proxy = (0, _proxify.default)(this, Object.assign({}, this.options, {
      bind: true
    }));
    return this.proxy;
  }

  clear(e) {
    this.emit("close", e);
    this.network = null;
    this.ws = null;
  }

  open() {
    return new Promise((resolve, reject) => {
      this.close().then(() => {
        this.ws = new this.options.engine(this.url, this.protocols, this.options.engineOptions);
        this.ws.binaryType = this.options.binaryType;

        this.ws.onopen = e => {
          this.emit("open", e);
          resolve(this.proxy);
        };

        this.ws.onerror = e => {
          this.emit("error", e);
          reject(e);
        };

        this.ws.onclose = e => {
          const {
            code
          } = e;
          this.clear(e);

          if (code !== _codes.CLOSE_NORMAL) {
            if (this.options.autoReconnect && !this.reconnecting) {
              this.reconnect();
            }
          }
        };

        this.ws.onmessage = e => this.network.read(e.data);

        this.network = new _Protocol.default(this.ws, this.options);
        this.network.on("*", (...args) => {
          this.emit(...args);
        });
      }).catch(reject);
    });
  }

  async reconnect(delay) {
    this.reconnecting = true;
    const timeout = delay || this.options.reconnectionMinimum;

    try {
      await this.open();
      this.reconnecting = false;
      this.emit("reconnect");
    } catch (e) {
      setTimeout(() => {
        this.reconnect(timeout * this.options.reconnectionFactor);
      }, timeout);
    }
  }

  close() {
    return new Promise(resolve => {
      if (this.ws) {
        this.ws.onclose = e => {
          this.clear(e);
          resolve(this.proxy);
        };

        this.ws.close();
      } else {
        resolve(this.proxy);
      }
    });
  }

  async send(message) {
    if (!this.network) {
      throw new Error(`Attempted to send command "${message.instruction.command}" without a connection being established`);
    }

    return this.network.send(message);
  }

}

exports.default = Client;
