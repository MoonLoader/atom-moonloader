MoonloaderSearchView = require './moonloader-search-view'
{CompositeDisposable} = require 'atom'
provider = require './provider'


module.exports =
  subscriptions: null
  searchView: null
  autocompleteProvider: null
  optionProvider: null

  activate: ->
    # install dependencies
    require('atom-package-deps').install('moonloader')
    # configure language-luajit package
    @languageLuajitOnlyKeywords = @atomConfigSet('language-luajit.onlyKeywords', true)
    # add commands
    @subscriptions = new CompositeDisposable
    @subscriptions.add(atom.commands.add('atom-text-editor',
      'moonloader:toggleSearch', => @toggleSearch()))

  deactivate: ->
    @subscriptions.dispose()
    @searchView?.destroy()
    atom.config.set('language-luajit.onlyKeywords', @languageLuajitOnlyKeywords)

  toggleSearch: ->
    @searchView ?= new MoonloaderSearchView
    @searchView.toggle()

  getAutocompletionProvider: ->
    @autocompleteProvider ?= new provider.SuggestionProvider

  getOptionProvider: ->
    @optionProvider ?= new provider.OptionProvider

  atomConfigSet: (key, value) ->
    oldValue = atom.config.get(key)
    atom.config.set(key, value)
    oldValue
