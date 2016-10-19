fs = require 'fs'
path = require 'path'

module.exports =
  selector: '.source.lua'
  disableForSelector: '.source.lua .comment, .source.lua .string'
  inclusionPriority: 10
  excludeLowerPriority: false

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix, activatedManually}) ->
    prefix = @getPrefix(editor, bufferPosition)
    return null if not prefix?
    return null if prefix.left.length < atom.config.get("moonloader.suggestAfterNthChar") and not prefix.delim?
    return @findOpcodes(prefix.right) if prefix.left is 'OPCODE_' and not prefix.delim?
    return null if prefix.delim is '.' and not @completions.libs[prefix.left]?
    return @findSuggestions(@completions.libs[prefix.left], prefix.right) if prefix.delim is '.'
    return @findSuggestions(@completions.members, prefix.right) if prefix.delim is ':'
    return @findSuggestions(@completions.words, prefix.left)
            .concat(@findSuggestions(@completions.opcodes, prefix.left))

  findSuggestions: (completions, prefix = '') ->
    suggestions = []
    for item in completions
      if @compareStrings(item.name, prefix)
        suggestions.push(@buildSuggestion(item))
    suggestions

  findOpcodes: (prefix = '') ->
    suggestions = []
    for item in @completions.opcodes
      if @compareStrings(item.opcode, prefix)
        suggestions.push(@buildSuggestion(item))
    suggestions

  buildSuggestion: (item) ->
    suggestion =
      type: item.type
      displayText: item.displayText
      snippet: item.snippet
      leftLabel: item.return

    if item.wiki?
      if item.wiki.en?
        suggestion.description = "Wiki (EN):"
        suggestion.descriptionMoreURL = item.wiki.en
      else if item.wiki.ru?
        suggestion.description = "Wiki (RU):"
        suggestion.descriptionMoreURL = item.wiki.ru

    switch item.type
      when "method"
        suggestion.rightLabel = item.class
      when "function"
        if item.opcode? then suggestion.rightLabel = "Opcode #{item.opcode}"
      when "package"
        suggestion.text = item.name
      when "var"
        suggestion.text = item.name
        suggestion.leftLabel = item.valueType

    suggestion

  loadCompletions: ->
    @completions = {}
    fs.readFile path.resolve(__dirname, '..', './data/autocompletion.json'), (error, data) =>
      @completions = JSON.parse(data) unless error?
    return

  getPrefix: (editor, bufferPosition) ->
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    # opcode search
    opRegex = /(OPCODE_)([0-9a-fA-F]{1,4})$/
    return left: res[1], right: res[2] if res = line.match(opRegex)

    regex = /([a-zA-Z_][\w]*)(\.|:)?([a-zA-Z_][\w]*)?$/
    res = line.match(regex)
    left: res[1], delim: res[2], right: res[3] if res?

  compareStrings: (str, substr) ->
    return false if substr.length > str.length
    substr.toUpperCase() == str.substring(0, substr.length).toUpperCase()
