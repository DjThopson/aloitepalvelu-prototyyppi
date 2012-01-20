# db seed
LAWS      = require('laws_seed').laws
PETITIONS = require('petitions_seed').petitions

exports.init_demo_db = (db, init_cb) ->

  initialize_collection = (col_name, seed, cb) ->
    col = db.collection col_name
    col.drop().run ->
      col.insertAll(seed).run (err) ->
        if err? then return cb err else return cb null

  # petitions seeding
  initialize_collection 'petitions', PETITIONS, (err) ->
    return init_cb err if err?
    console.log "SEED: petitions seeded"
    # laws seeding
    initialize_collection 'laws', LAWS, (err) ->
      return init_cb err if err?
      console.log "SEED: laws seeded"
      init_cb null
