path = require 'path'
fs = require 'fs'
{$$, SelectListView} = require 'atom-space-pen-views'


module.exports =
class MoonloaderSearchView extends SelectListView
  lastSearch: ''

  initialize: ->
    super
    @loadSearchDatabase('./data/search.json')
    @panel = atom.workspace.addModalPanel(item: this, visible: false)

  destroy: ->
    @panel?.destroy()
    @detach()

  getFilterKey: ->
    if @isLookingForOpcode() then 'opcode' else 'name'

  getFilterQuery: ->
    text = @filterEditorView.getText()
    if @isLookingForOpcode() then text.substr(1) else text

  viewForItem: ({name, argsDisplay = '', returnDisplay, opcode, type}) ->
    $$ ->
      @li class: 'two-lines', =>
        @span "#{opcode}", class: 'pull-right highlight-info' if opcode
        icon = ' icon icon-chevron-right' if type is 'event'
        @div class: "primary-line#{icon ? ''}", =>
          @raw "<b>#{name}(</b>#{argsDisplay}<b>)</b>"
        if returnDisplay
          @div class: 'secondary-line', =>
            @raw "Returns: <i>#{returnDisplay}</i>"

  confirmed: (item) ->
    @insertItemText(item)
    @focusActiveTextEditor()
    @toggle(false)

  cancelled: ->
    @toggle(false)

  populateList: ->
    return if @filterEditorView.getText().length == 1
    super
    @lastSearch = @filterEditorView.getText()

  loadSearchDatabase: (filepath) ->
    fs.readFile path.resolve(__dirname, '..', filepath), (error, data) =>
      @setItems(JSON.parse(data).data) unless error?
      return

  insertItemText: ({name, args = '', ret, type}) ->
    editor = atom.workspace.getActiveTextEditor()
    text = ''
    if type is 'function'
      text = "local #{ret} = " if ret and not @isAnyTextBeforeCursor(editor)
      text += "#{name}(#{args})"
    else if type is 'event'
      text = "function #{name}(#{args})\n\n\t"
      text += "-- return #{ret}\n" if ret
      text += "end\n"
    editor.insertText(text)

  isAnyTextBeforeCursor: (editor) ->
    pos = editor.getCursorBufferPosition()
    text = editor.getTextInRange([[pos.row, 0], pos])
    text.trim().length isnt 0

  isLookingForOpcode: ->
    return @filterEditorView.getText()[0] is '@'

  toggle: (show) ->
    if show is true
      @filterEditorView.setText(@lastSearch)
      @panel.show()
      @focusFilterEditor()
      @populateList()
    else if show is false
      @panel.hide()
      @focusActiveTextEditor()
    else
      @toggle(not @panel.isVisible())

  focusActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()?.element.focus()
