var path = require('path');

module.exports = {
  entry: [
    'babel-polyfill',
    './src/client-ex.mjs'
  ],
  output: {
      publicPath: '/',
      filename: 'webpack.js'
  },
//  debug: true,
  devtool: 'source-map',
  module: {
    rules: [
      { 
        test: /\.mjs$/,
        include: path.join(__dirname, 'src'),
        loader: 'babel-loader',
      },
      { 
        test: /\.less$/,
      },
    ]
  },
  devServer: {
    contentBase: "./src"
  },
  resolve: {
    modules: ["node_modules", path.join(__dirname, 'src') ],
  }

};
