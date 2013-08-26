class SettingsManager extends KDObject

  constructor: (@filefullpath) ->
    super()
    result = filefullpath.match("^(.+)/[^/]+$")
    @settings = {}
    @filepath = result[1]
    @filename = result[2]
    @settingsfile = ".goproject.conf"
    @settingspath = @filepath + "/" + @settingsfile
    @readConfigFile()

  parseContent: (content) ->
    try
      @settings = JSON.parse content
      @emit 'ready'
    catch exc
      if exc instanceof SyntaxError
        kite    = KD.getSingleton 'kiteController'
        kite.run "echo '' > #{@settingspath}", (err, res) =>
          @emit 'ready'
      else
        throw exc

  readConfigFile: (callback) ->
    kite    = KD.getSingleton 'kiteController'
    kite.run "touch #{@settingspath}", (err, res) =>
      @file   = FSHelper.createFileFromPath @settingspath
      @file.fetchContents (err, content) =>
        if err
          console.log err
        else
          @parseContent content
          callback?()

  getSetting: (key) ->
    return @settings[@filefullpath]?[key]

  saveConfigFile: ->
    @ready =>
      console.log @settings
      fileContent = JSON.stringify @settings
      @file.save fileContent
  
  setConfig: (filename, key, value) ->
    (@settings[filename] or @settings[filename] = {})[key] = value