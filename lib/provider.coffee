fs = require 'fs'
path = require 'path'
autocompletionData = null


loadAutocompletionData = ->
  new Promise (resolve) ->
    return resolve(autocompletionData) if autocompletionData
    fs.readFile path.resolve(__dirname, '..', './data/autocompletion.json'), (error, data) ->
      throw error if error
      resolve(autocompletionData = JSON.parse(data))


class exports.OptionProvider
  priority: 20

  getLoadedOptions: (utils) ->
    new Promise (resolve) =>
      return resolve(@loadedOptions) if @loadedOptions
      loadAutocompletionData()
      .then (data) =>
        resolve(@loadedOptions = utils.reviveOptions(data))

  getOptions: (request, getPreviousOptions, utils, cache) ->
    @getLoadedOptions(utils)
    .then (newOptions) ->
      previousOptions = getPreviousOptions()
      return options: previousOptions if not newOptions?
      utils.mergeOptionsCached(previousOptions, newOptions, cache)


class exports.SuggestionProvider
  selector: '.source.lua'
  disableForSelector: '.source.lua .comment, .source.lua .string'
  inclusionPriority: 10
  excludeLowerPriority: false

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix, activatedManually}) ->
    if prefix?.length >= 2 or activatedManually
      loadAutocompletionData()
      .then (data) =>
        @findSuggestions(data.snippets, prefix)

  findSuggestions: (completions, prefix) ->
    suggestions = []
    for name, item of completions
      if @compareStrings(name, prefix)
        suggestions.push(@buildSuggestion(name, item))
    suggestions

  buildSuggestion: (name, item) ->
    suggestion =
      name: name
      snippet: item.snippet
      type: item.type
      displayText: item.displayText
      descriptionMarkdown: item.descriptionMarkdown

  compareStrings: (str, substr) ->
    return false if substr.length > str.length
    substr == str.substring(0, substr.length)
