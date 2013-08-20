class GoIDEWorkspace extends CollaborativeWorkspace
  constructor: (options, data) ->
    super(options, data)
    @on "PanelCreated", ->
      hideAtFirstList = ["Test", "Run", "Build", "PlayGolang Share"]
      for button in hideAtFirstList
        @getButtonByTitle(button).hide()
    
    @on "AllPanesAddedToPanel", (panel, panes) ->
      editor = panel.getPaneByName("editor")
      {codeMirrorEditor} = editor.getActivePane().subViews[0]
      codeMirrorEditor.getWrapperElement().style.fontSize = "12px"
      {tabView} = editor
      tabView.on "PaneAdded", (paneInstance) =>
        [editor] = paneInstance.getSubViews()
        editor.on "OpenedAFile", (file, content) =>
          @makeButtonControls panel
          
      tabView.on "PaneDidShow", (tabPane) =>
        @makeButtonControls panel

  getButtonByTitle: (title) ->
    panel = @panels[0]
    return panel.headerButtons[title]
  
  makeButtonControls: (panel) ->
    filepath = getActiveFilePath panel
    return unless filepath
    filecontent = panel.getPaneByName('editor').getActivePaneContent()
    
    controlsList = [
      ["Test", -> filepath isnt null and filepath.match(".*_test.go")],
      ["Run", -> filepath isnt null and (filecontent.indexOf 'package main') isnt -1],
      ["Build", -> filepath.match(".*.go")],
      ["examplesSelect", -> filepath.match(".*.go")]
    ]
    
    for control in controlsList
      button = @getButtonByTitle(control[0])
      if control[1]()
        button.show()
      else
        button.hide()
