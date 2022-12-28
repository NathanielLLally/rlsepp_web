// rollup.config.js

import { nodeResolve } from '@rollup/plugin-node-resolve';
export default {
  input:  'src/server-ex.mjs',
  output: {
    file: 'server.js',
    format: 'es',
    sourcemap: false,
  },
  plugins: [
    nodeResolve(),
  ]
};
