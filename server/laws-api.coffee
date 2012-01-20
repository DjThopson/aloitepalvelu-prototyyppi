exports.init_laws_api = (app, db) ->
  BSON = require('mongodb').BSONNative
  col = db.collection 'laws'

  find_laws = (cb) ->
    col.find().run (err, arr) ->
      return if err? then cb err, null else cb null, arr

  find_law_by_id = (id, cb) ->
    o_id = BSON.ObjectID.createFromHexString(id)
    col.find(_id: o_id).run (err, arr) ->
      return cb err, null if err?
      cb null, arr[0]

  find_law_by_common_name = (cn, cb) ->
    col.find({"common_name":cn}).run (err, arr) ->
      return if err? then cb err, null else cb null, arr[0]

  find_laws_index_by_names = (cb) ->
    col.find().fields({"common_name":1, "name" :1}).run (err,arr) ->
      return if err? then cb err, null else cb null, arr

  # api
  app.get "/api/law_cn/:cn", (req, res) ->
      find_law_by_common_name req.params.cn, (err, json) ->
        if err? then res.send 500 else res.send json

  app.get "/api/laws", (req, res) ->
      find_laws (err, json) ->
        if err? then res.send 500 else res.send json

  app.get "/api/laws_index", (req, res) ->
      find_laws_index_by_names (err, json) ->
        if err? then res.send 500 else res.send json

  app.get "/api/law/:id", (req, res) ->
    return res.send {err: "invalid id"}, 422 if not is_valid_id req.params.id
    find_law_by_id req.params.id, (err, json) ->
      return res.send 500 if err?
      return res.send 404 if not json?
      res.send json
