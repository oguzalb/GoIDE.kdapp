getActiveFilePath = (panel) ->
  activePaneFileData = panel.getPaneByName("editor").getActivePaneFileData()
  return unless activePaneFileData
  {path} = activePaneFileData
  return if path.indexOf "localfile:/" isnt 0 then path.replace /[^/]*/, "" else null

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
        }
        {
          title      : "Test"
          cssClass   : "clean-gray"
          callback   : (panel, workspace) =>
            filepath = getActiveFilePath panel
            if filepath isnt null
              if filepath.match(".*_test.go")
                panel.getPaneByName("terminal").runCommand("go test #{filepath}")
        }
        {
          title      : "Build"
          cssClass   : "clean-gray"
          callback   : (panel, workspace) =>
            filepath = getActiveFilePath panel
            if filepath isnt null
              if filepath.match(".*.go")
                path = filepath.match("^(.+)/[^/]+$")[1]
                terminal = panel.getPaneByName "terminal"
                terminal.runCommand "cd #{path}"
                terminal.runCommand "go get -v -d ."
                terminal.runCommand "go build #{filepath}"
        }
        {
          title      : "Terminal"
          cssClass   : "clean-gray"
          callback   : (panel, workspace) ->
            workspace.toggleTerminal()
        }
        {
          title      : "Gist Share"
          cssClass   : "clean-gray"
          callback   : (panel, workspace) =>
            filepath = getActiveFilePath panel
            if filepath isnt null
              filecontent = panel.getPaneByName('editor').getActivePaneContent()
              filename = filepath.match "([^/]*$)"
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
        }
        {
          itemClass: KDSelectBox
          title: "examplesSelect"
          defaultValue: sampleCodesItems[0][1]
          cssClass: 'fr goide-examples'
          selectOptions: {title: item[0], value: item[1]} for item in sampleCodesItems
          callback: () =>
            selectBox = goIDE.getButtonByTitle "examplesSelect"
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
              sampleData = sampleCodesData[value]
              file.save sampleData[0], (err, res)->
                return if err
                editor = goIDE.panels[0].getPaneByName("editor")
                goIDE.toggleTerminal(true)
                terminal = goIDE.panels[0].getPaneByName("terminal")
                editor.openFile file, sampleData[0]
                sampleDataLength = sampleData.length
                if sampleData.length is 2 then kite.run sampleData[1].requirementQuery, (err, res) ->
                  requirements = sampleData[1]
                  if err is null
                    if !(res.match requirements.requirementCheck)
                      command = requirements.fullfill
                      terminal.runCommand command
                else if sampleData[1].requirementQuery
                  command = sampleData[1].fullfill
                  terminal.runCommand command                  
        }
      ]
      layout            : {
        direction       : "vertical"
        sizes           : [ "20%", "40%", "40%" ]
        views           : [
          {
            type        : "finder"
            name        : "finder"
          }
          {
            type         : "tabbedEditor"
            name         : "editor"
            saveCallback : (panel, workspace, file, content) ->
              filepath = getActiveFilePath panel
              if filepath isnt null and filepath.match(".*.go$")
                try
                  # TODO we may show the user what is going on, or may be not
                  # panel.getPaneByName("terminal").runCommand "go fmt #{filepath}"
                  KD.getSingleton("vmController").run "go fmt #{filepath}", (err, res) ->
                    goIDE.makeButtonControls panel
                    {codeMirrorEditor} = panel.getPaneByName("editor").getActivePane().subViews[0]
                    oldCursor = codeMirrorEditor.getCursor()
                    file = FSHelper.createFileFromPath filepath
                    file.fetchContents (err, content) ->
                      codeMirrorEditor.setValue content
                      codeMirrorEditor.refresh()
                      codeMirrorEditor.setCursor oldCursor.line
                catch ex
                  console.log ex
          }
          {
            type    : "terminal"
            name    : "terminal"
          }
        ]
      }
    }
  ]

goIDE = new GoIDEWorkspace options
appView.addSubView goIDE
