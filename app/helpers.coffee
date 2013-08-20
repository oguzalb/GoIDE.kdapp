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
  