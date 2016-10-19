provider = require './provider'

module.exports =
  config:
    suggestAfterNthChar:
      type: 'integer'
      default: 2

  activate: ->
    require('atom-package-deps').install('moonloader')
    provider.loadCompletions()
  provide: ->
    provider
