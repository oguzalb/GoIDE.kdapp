getSampleCode = (name) ->
  for vals in sampleCodes
    if vals[0] is name
      return vals[1]

sampleCodes = [
  ["Select", """"""]
  ["Hello World", """package main

import (
  "fmt"
)

main() {
  fmt.Println("Hello world!")
}"""],
  ["Strings", """package main

import (
  "fmt"
	"strings"
)

func main() {
	fmt.Println(strings.Contains("seafood", "foo"))
	fmt.Println(strings.Contains("seafood", "bar"))
	fmt.Println(strings.Contains("seafood", ""))
	fmt.Println(strings.Contains("", ""))
}"""]
]

getActiveFilePath = (panel) ->
  rawpath = panel.getPaneByName("editor").getActivePaneFileData().path
  if (rawpath.indexOf "localfile:/") isnt 0
    return rawpath.replace /[^/]*/, ""
  return null

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
      buttons        : [
        {
          title      : "Join"
          cssClass   : "cupid-green join-button"
          callback   : (panel, workspace) =>
            workspace.showJoinModal()
        }
        {
          title      : "Go Run"
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
          title      : "Go Test"
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
          defaultValue: sampleCodes[0][1]
          cssClass: 'fr'
          selectOptions: {title: item[0], value: item[1]} for item in sampleCodes
          callback: () =>
            selectBox = getButtonByIndex goIDE, 5
            content = selectBox.getValue()
            filepath = "localfile:/untitled.go"
            file = FSHelper.createFile {type: "file", path: filepath}
            editor = goIDE.panels[0].getPaneByName("editor")
            editor.openFile(file, null)
            cmEditor = editor.getActivePane().subViews[0].codeMirrorEditor
            cmEditor.setValue content
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
                  if filepath isnt null
                    # TODO we may show the user what is going on, or may be not
                    # panel.getPaneByName("terminal").runCommand "go fmt #{filepath}"
                    KD.getSingleton("vmController").run "go fmt #{filepath}", (err, res) ->
                      makeButtonControls(panel)
                      {codeMirrorEditor} = panel.getPaneByName("editor").getActivePane().subViews[0]
                      
                      file = FSHelper.createFileFromPath filepath
                      file.fetchContents (err, content) ->
                        codeMirrorEditor.setValue content
                        codeMirrorEditor.refresh()
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
  
getButtonByIndex = (workspace, index) ->
  # getButtonByName would be better
  buttons = workspace.panels[0].header
  return buttons.subViews[index]

makeButtonControls = (panel) ->
  filepath = getActiveFilePath panel
  testButton = getButtonByIndex(goIDE, 2)
  if filepath isnt null and filepath.match(".*_test.go")
    testButton.show()
  else
    testButton.hide()
  filecontent = panel.getPaneByName('editor').getActivePaneContent()
  runButton = getButtonByIndex(goIDE, 1)
  if (filecontent.indexOf 'package main') isnt -1
    runButton.show()
  else
    runButton.hide()

goIDE = new CollaborativeWorkspace options
goIDE.on "PanelCreated", ->
  getButtonByIndex(goIDE, 2).hide()
  getButtonByIndex(goIDE, 1).hide()
  getButtonByIndex(goIDE, 4).hide()

goIDE.on "AllPanesAddedToPanel", (panel, panes) ->
  tabView = panel.getPaneByName("editor").tabView
  tabView.on "PaneDidShow", (tabPane) ->
    # TODO should be fixed
    KD.utils.wait 1000, ->
      makeButtonControls(panel)

appView.addSubView goIDE
