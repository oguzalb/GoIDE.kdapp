getActiveFilePath = (panel) ->
  rawpath = panel.getPaneByName("editor").getActivePaneFileData().path
  if (rawpath.indexOf "localfile:/") isnt 0
    return rawpath.replace /[^/]*/, ""
  return null

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
  kite.run "mkdir -p ~/.kodepad", (err, res) ->
    
    tmpFile = "/home/#{nickname}/.kodepad/.gist.tmp"
    
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
                title: "Kodepad is creating your Gist..."
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
