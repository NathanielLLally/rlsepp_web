// rollup.config.js

import polyfill from 'rollup-plugin-node-polyfills';
import resolve from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';
export default {
  input:  'src/client-ex.mjs',
  output: {
    file: 'client.js',
    format: 'iife',
    sourcemap: true,
  },
  plugins: [
    polyfill(),
    resolve({
      browser: true
    }),
    commonjs({
      include: '/node_modules/**',
    })
  ]
};
