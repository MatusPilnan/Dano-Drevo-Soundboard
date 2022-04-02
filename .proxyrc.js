const express = require('express')
const path = require('path')

module.exports = function (app) {
  app.use('/content', express.static(path.join(__dirname, '/content'), {index: ['index.json']}))
}