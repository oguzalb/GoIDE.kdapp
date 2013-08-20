getActiveFilePath = (panel) ->
  activePaneFileData = panel.getPaneByName("editor").getActivePaneFileData()
  return unless activePaneFileData
  
  {path} = activePaneFileData
  return if path.indexOf "localfile:/" isnt 0 then path.replace /[^/]*/, "" else null

createPlayGolangShare = (filecontent, callback) ->
  {nickname} = KD.whoami().profile
  kite    = KD.getSingleton 'kiteController'
  kite.run "mkdir -p ~/.GoIDE", (err, res) ->
    
    tmpFile = "/home/#{nickname}/.GoIDE/.playgolang.tmp"
    
    tmp = FSHelper.createFileFromPath tmpFile
    filecontent = filecontent.replace /\n/g, "\n\r"
    tmp.save filecontent, (err, res)->
      return if err
      
      kite.run "curl -kLss -X POST http://play.golang.org/share --data @#{tmpFile}", (err, res)->
        KD.enableLogs()
        console.log err, res
        callback err, res

createGist = (filecontent, filename, callback) ->
  
  {nickname} = KD.whoami().profile
  
  gist = 
    description: """
    Kodepad Gist Share by #{nickname} on http://koding.com
    Author: http://#{nickname}.koding.com
    """
    public: yes
    files:
      "index.coffee": {content: filecontent}

  kite    = KD.getSingleton 'kiteController'
  kite.run "mkdir -p ~/.GoIDE", (err, res) ->
    
    tmpFile = "/home/#{nickname}/.GoIDE/.gist.tmp"
    
    tmp = FSHelper.createFileFromPath tmpFile
    tmp.save JSON.stringify(gist), (err, res)->
      return if err
      
      kite.run "curl -kLss -A\"Koding\" -X POST https://api.github.com/gists --data @#{tmpFile}", (err, res)->
        KD.enableLogs()
        console.log err, res
        callback err, JSON.parse(res)
        #kite.run "rm -f #{tmpFile}"
  
options =
  name               : "Go IDE"
  version            : "0.1"
  joinModalTitle     : "Join your friend's code"
  joinModalContent   : "<p>Paste the session key that you received and start coding together.</p>"
  shareSessionKeyInfo: "<p>This is your session key, you can share this key with your friends to work together.</p>"
  firebaseInstance   : "go-ide"
  enableChat         : yes
  panels             : [
    {
      title          : "Go IDE"
      hint           : "<p>This is an IDE for GO lang.</p>"
      buttons        : [
        {
          title      : "Join"
          cssClass   : "cupid-green join-button"
          callback   : (panel, workspace) =>
            workspace.showJoinModal()
        }
        {
          title      : "Run"
          cssClass   : "clean-gray"
          callback   : (panel, workspace) =>
            filepath = getActiveFilePath panel
            if filepath isnt null
              filecontent = panel.getPaneByName('editor').getActivePaneContent()
              if (filecontent.indexOf 'package main') isnt -1 
                panel.getPaneByName("terminal").runCommand("go run #{filepath}")
            else
              console.log("untitled!")
        }
        {
          title      : "Test"
          cssClass   : "clean-gray"
          callback   : (panel, workspace) =>
            filepath = getActiveFilePath panel
            if filepath isnt null
              if filepath.match(".*_test.go")
                panel.getPaneByName("terminal").runCommand("go test #{filepath}")
            else
              console.log("not a test file!")
        }
        {
          title      : "Build"
          cssClass   : "clean-gray"
          callback   : (panel, workspace) =>
            filepath = getActiveFilePath panel
            if filepath isnt null
              if filepath.match(".*.go")
                path = filepath.match("^(.+)/[^/]+$")[1]
                panel.getPaneByName("terminal").runCommand("cd #{path}")
                panel.getPaneByName("terminal").runCommand("go get -v -d .")
                panel.getPaneByName("terminal").runCommand("go build #{filepath}")
            else
              console.log("not a test file!")
        }
        {
          title      : "Gist Share"
          cssClass   : "clean-gray"
          callback   : (panel, workspace) =>
            filepath = getActiveFilePath panel
            if filepath isnt null
              filecontent = panel.getPaneByName('editor').getActivePaneContent()
              filename = filepath.match("([^/]*$)")
              new KDNotificationView 
                title: "GoIDE is creating your Gist..."
              createGist filecontent, filename, (err, res)->
                if err
                  new KDNotificationView 
                    title: "An error occured while creating gist, try again."
                modal = new KDModalView
                  overlay : yes
                  title     : "Your Gist is ready!"
                  content   : """
                                  <div class='modalformline'>
                                    <p><b>#{res.html_url}</b></p>
                                  </div>
                              """
                  buttons     :
                    "Open Gist":
                      cssClass: "modal-clean-green"
                      callback: ->
                        window.open res.html_url, "_blank"
              
            else
              console.log("untitled!")
        }
        {
          title      : "PlayGolang Share"
          cssClass   : "clean-gray"
          callback   : (panel, workspace) =>
            filepath = getActiveFilePath panel
            if filepath isnt null
              filecontent = panel.getPaneByName('editor').getActivePaneContent()
              filename = filepath.match("([^/]*$)")
              new KDNotificationView 
                title: "GoIDE is creating your code share..."
              createPlayGolangShare filecontent, (err, res)->
                if err
                  new KDNotificationView 
                    title: "An error occured while creating code share, try again."
                url = "http://play.golang.org/p/" + res
                modal = new KDModalView
                  overlay : yes
                  title     : "Your code share is ready!"
                  content   : """
                                  <div class='modalformline'>
                                    <p><b>#{url}</b></p>
                                  </div>
                              """
                  buttons     :
                    "Open Play Golang Share":
                      cssClass: "modal-clean-green"
                      callback: ->
                        window.open url, "_blank"
              
            else
              console.log("untitled!")
        }
        {
          itemClass: KDSelectBox
          title: "examplesSelect"
          defaultValue: sampleCodesItems[0][1]
          cssClass: 'fr goide-examples'
          selectOptions: {title: item[0], value: item[1]} for item in sampleCodesItems
          callback: () =>
            selectBox = getButtonByTitle goIDE, "examplesSelect"
            #default
            if selectBox.getValue() is ""
              return
            value = selectBox.getValue()
            kite    = KD.getSingleton 'kiteController'
            {nickname} = KD.whoami().profile
            examplesPath = "/home/#{nickname}/Documents/go-examples/"
            kite.run "mkdir -p #{examplesPath}", (err, res) ->
              sampleFileName = examplesPath + value + ".go"
              file = FSHelper.createFileFromPath sampleFileName
              file.save sampleCodesData[value], (err, res)->
                return if err
                editor = goIDE.panels[0].getPaneByName("editor")
                editor.openFile(file, sampleCodesData[value])
        }
      ]
      layout            : {
        direction       : "vertical"
        sizes           : [ "20%", null ]
        views           : [
          {
            type        : "finder"
            name        : "finder"
          }
          {
            type        : "split"
            options     :
              direction : "vertical"
              sizes     : ["50%", null]
            views       : [
              {
                type         : "tabbedEditor"
                name         : "editor"
                saveCallback : (panel, workspace, file, content) -> 
                  filepath = getActiveFilePath panel
                  if filepath isnt null and filepath.match(".*.go$")
                    # TODO we may show the user what is going on, or may be not
                    # panel.getPaneByName("terminal").runCommand "go fmt #{filepath}"
                    KD.getSingleton("vmController").run "go fmt #{filepath}", (err, res) ->
                      makeButtonControls(goIDE, panel)
                      {codeMirrorEditor} = panel.getPaneByName("editor").getActivePane().subViews[0]
                      oldCursor = codeMirrorEditor.getCursor()
                      file = FSHelper.createFileFromPath filepath
                      file.fetchContents (err, content) ->
                        codeMirrorEditor.setValue content
                        codeMirrorEditor.refresh()
                        codeMirrorEditor.setCursor(oldCursor.line)
                  else
                    console.log("untitled!")
              }
              {
                type    : "terminal"
                name    : "terminal"
              }
            ]
          }
        ]
      }
    }
  ]
  
getButtonByTitle = (workspace, title) ->
  # getButtonByName would be better
  panel = workspace.panels[0]
  return panel.headerButtons[title]

makeButtonControls = (workspace, panel) ->
  filepath = getActiveFilePath panel
  return unless filepath
  testButton = getButtonByTitle(workspace, "Test")
  if filepath isnt null and filepath.match(".*_test.go")
    testButton.show()
  else
    testButton.hide()
  filecontent = panel.getPaneByName('editor').getActivePaneContent()
  runButton = getButtonByTitle(workspace, "Run")
  if filepath isnt null and (filecontent.indexOf 'package main') isnt -1
    runButton.show()
  else
    runButton.hide()
  buildButton = getButtonByTitle(workspace, "Build")
  if filepath.match(".*.go")
    buildButton.show()
  else
    buildButton.hide()
  selectBox = getButtonByTitle(workspace, "examplesSelect")
  if filepath.match(".*.go")
    buildButton.show()
  else
    buildButton.hide()

goIDE = new CollaborativeWorkspace options
goIDE.on "PanelCreated", ->
  getButtonByTitle(goIDE, "Test").hide()
  getButtonByTitle(goIDE, "Run").hide()
  getButtonByTitle(goIDE, "Build").hide()
  getButtonByTitle(goIDE, "PlayGolang Share").hide()

goIDE.on "AllPanesAddedToPanel", (panel, panes) ->
  editor = panel.getPaneByName("editor")
  {codeMirrorEditor} = editor.getActivePane().subViews[0]
  codeMirrorEditor.getWrapperElement().style.fontSize = "12px"
  {tabView} = editor
  tabView.on "PaneAdded", (paneInstance) ->
    [editor] = paneInstance.getSubViews()
    editor.on "OpenedAFile", (file, content) ->
      makeButtonControls goIDE, panel
      
  tabView.on "PaneDidShow", (tabPane) ->
    makeButtonControls(goIDE, panel)

appView.addSubView goIDE


