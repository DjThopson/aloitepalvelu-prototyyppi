express = require('express')
http    = require('http')
stylus  = require('stylus')

MongoStore = require('connect-mongo')

emailsender  = require('emailsender')
petitions    = require('petitions-api')
laws         = require('laws-api')
demodata     = require('demodata')

create_app = (settings, db) ->

    PUBLIC = settings.app.root + "/public"
    COFFEE = settings.app.root + "/client"
    STYLUS = settings.app.root + "/client/stylus"
    VIEWS  = settings.app.root + "/views"

    app = express.createServer()

    store = new MongoStore(db:db.cfg.dbname)

    app.configure ->
        app.use stylus.middleware
            debug: false
            compress: true
            src: STYLUS
            dest: PUBLIC

        app.use express.compiler
            src: COFFEE
            dest: PUBLIC
            enable: ['coffeescript']

        app.use express.cookieParser()
        app.use express.bodyParser()
        app.use express.session {secret: "TODO", store:store}
        app.use express.static PUBLIC

    app.configure "development", ->
        app.use express.logger()
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true

    app.configure "staging", ->
        app.use express.logger()
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true

    app.configure "production", ->
        app.use express.logger()
        app.use express.errorHandler()

    app.register '.html', require('ejs')
    app.set 'view engine', 'jade'
    app.set "views", VIEWS

    app.get "/", (req, res) ->
        res.render('index', {layout: false})

    app.get "/init_demo", (req, res) ->
        demodata.init_demo_db db, (err) ->
            if err?
                res.send err
            else
                res.send "OK"

    emailsender.init_emailsender settings, app, db
    petitions.init_petitions_api settings, app, db
    laws.init_laws_api app,db

    # redirect other urls to index with hashed route
    app.get "^*", (req, res) ->
        res.redirect "#/#{req.url}"

    return app

exports.create_app = create_app
