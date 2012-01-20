APPROOT       = __dirname
SETTINGS_FILE = "#{APPROOT}/settings.json"

require.paths.unshift './node_modules'
require.paths.push 'server'
require.paths.push 'server/js'

fs     = require('fs')
monmon = require('monmon').monmon

settings          = JSON.parse fs.readFileSync(SETTINGS_FILE)
settings.app.root = APPROOT

db  = monmon.use(settings.app.name)
app = require('app').create_app settings, db

app.listen(settings.server.port)
console.log "Server is listening to port: #{settings.server.port}"
