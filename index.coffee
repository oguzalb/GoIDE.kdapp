getActiveFilePath = (panel) ->
  rawpath = panel.getPaneByName("editor").getActivePaneFileData().path
  if (rawpath.indexOf "localfile:/") isnt 0
    return rawpath.replace /[^/]*/, ""
  return null

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
                panel.panes[2].runCommand("go run #{filepath}")
            else
              console.log("untitled!")
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
                  log panel, workspace, file, content
                  debugger
                  filepath = getActiveFilePath panel
                  if filepath isnt null
                    # TODO we may show the user what is going on, or may be not
                    # panel.getPaneByName("terminal").runCommand "go fmt #{filepath}"
                    KD.getSingleton("vmController").run "go fmt #{filepath}", (err, res) ->
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

goIDE = new CollaborativeWorkspace options
appView.addSubView goIDE

