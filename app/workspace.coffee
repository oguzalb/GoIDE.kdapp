class GoIDEWorkspace extends CollaborativeWorkspace
  constructor: (options, data) ->
    super options, data
    @terminalToggled = false
    @on "PanelCreated", ->
      hideAtFirstList = ["Test", "Run", "Build", "Settings"]
      for button in hideAtFirstList
        editor = @panels[0].getPaneByName "editor"
        {codeMirrorEditor} = editor.getActivePane().subViews[0]
        codeMirrorEditor.getWrapperElement().style.fontSize = "12px"
        @getButtonByTitle(button).hide()
    
    @on "AllPanesAddedToPanel", (panel, panes) ->
      console.log "allpanesadded"
      editor = panel.getPaneByName "editor"
      terminal = panel.getPaneByName "terminal"
      terminal.webterm.on "WebTermConnected", ->
        console.log "webtermconnected"
        kite    = KD.getSingleton 'kiteController'
        {nickname} = KD.whoami().profile
        GOPATH = "/home/#{nickname}/.GoIDE/go"
        kite.run "mkdir -p ~/.GoIDE/go", (err, res) ->
          terminal.runCommand "export GOPATH=#{GOPATH}"
      {tabView} = editor
      tabView.on "PaneAdded", (paneInstance) =>
        [editor] = paneInstance.getSubViews()
        editor.on "OpenedAFile", (file, content) =>
          @makeButtonControls panel
          editor.codeMirrorEditor.getWrapperElement().style.fontSize = "12px"
          
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
      ["Test", -> filepath?.match ".*_test.go"],
      ["Run", -> filepath isnt null and (filecontent.indexOf 'package main') isnt -1],
      ["Build", -> filepath?.match ".*.go"],
      ["examplesSelect", -> filepath?.match ".*.go"]
      ["Gist Share", -> filepath?.match ".*.go"]
      ["Settings", -> filepath?.match ".*.go"]
    ]
    
    for control in controlsList
      button = @getButtonByTitle control[0]
      if control[1]()
        button.show()
      else
        button.hide()

  toggleTerminal: (visible) ->
    splitView = goIDE.panels[0].layoutContainer
    if @terminalToggled or visible ? !!visible
      splitView.subViews[0].resizePanel("40%", 2)
      @terminalToggled = false
    else
      splitView.subViews[0].resizePanel("0%", 2)
      @terminalToggled = true