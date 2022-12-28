// rollup.config.js

import polyfill from 'rollup-plugin-node-polyfills';
import commonjs from '@rollup/plugin-commonjs';
import { nodeResolve } from '@rollup/plugin-node-resolve';
export default {
  input:  'src/client-ex.mjs',
  output: {
    file: 'client.js',
    format: 'iife',
    sourcemap: false,
  },
  plugins: [
    polyfill(),
    nodeResolve(),
    commonjs({
include: 'node_modules/**', // Default: undefined
                        }),
  ]
};
