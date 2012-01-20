_     = require('underscore')
email = require('emailsender')

# demo settings
VERIFY_VEVS_DELAY       = 5000
NOTIFICATION_EMAIL      = "" #where to send email notifications
DEMO_USER               = "Petteri Ruponen"

# validation settings
MANDATORY_FIELDS = ["name","date","type","support","law_proposal","rationale",
                    "initiators","representatives","reserves"]
OPTIONAL_FIELDS  = ["keywords","support_url","homepage_url","law_proposal_attachments",
                    "rationale_attachments", "law_references"]

exports.init_petitions_api = (settings, app, db) ->
  BSON = require('mongodb').BSONNative
  col = db.collection 'petitions'

  validate_petition = (json, cb) ->
    err      = []
    json_tmp = _.clone(json)

    # mandatory
    for field in MANDATORY_FIELDS
      if not json_tmp[field]?
        err.push "missing attribute #{field}"
      else
        err.push "missing attribute #{field}" if json_tmp[field] == ""
        delete json_tmp[field]
    # optional
    for field in OPTIONAL_FIELDS
      delete json_tmp[field] if json_tmp[field]?
    # check for unknown fields
    err.push "unknown attribute #{field}" for field, value of json_tmp

    return cb null if _.isEmpty(err)
    console.log "invalid petition:"
    console.log err
    cb err

  is_valid_id = (id) ->
    id?.match /^[0-9a-f]{24}$/

  create_petition = (json, cb) ->
    json["author"]        = DEMO_USER
    json["state"]         = "draft"
    json["created_at"]    = new Date()
    json["support_votes"] = 0

    json["keywords"]      = json.keywords?.map (i) -> keyword: i

    json["initiators"]      = json.initiators?.map (i)      -> email: i
    json["representatives"] = json.representatives?.map (i) -> email: i
    json["reserves"]        = json.reserves?.map (i)        -> email: i

    json["law_proposal_attachments"] = json.law_proposal_attachments?.map (i) -> law_proposal_attachment: i
    json["rationale_attachments"]    = json.rationale_attachments?.map (i) -> rationale_attachment: i

    console.log json
    col.insert(json).run (err, arr) ->
      return cb err if err?
      id = arr[0]._id
      cb null, id

  authorize = (id, author, cb) ->
    find_petition_by_id id, (err, petition) ->
      return cb err if err?
      return cb null if petition.author == author
      err = "ERROR: not authorized"
      console.log err
      cb err

  find_petitions = (cb) ->
    col.find().run (err, arr) ->
      return if err? then cb err, null else cb null, arr

  find_petition_by_id = (id, cb) ->
    o_id = BSON.ObjectID.createFromHexString(id)
    col.find(_id: o_id).run (err, arr) ->
      return cb err, null if err?
      cb null, arr[0]

  find_petitions_by_author = (author, cb) ->
    col.find(author : author).sort(created_at: -1).run (err, arr) ->
      return cb err if err?
      cb null, arr

  filter_petitions_by_states = (states, cb) ->
    states = states.map (state) ->
      state: state
    console.log "filter petitions by states:"
    console.log states
    col.find($or: states).run (err, arr) ->
      return if err? then cb err, null else cb null, arr

  find_votable_petitions = (cb) ->
    col.find(state: "om_approved").sort(created_at : -1).run (err, arr) ->
      if err? then cb err, null else cb null, arr

  find_petitions_in_parliament = (cb) ->
    col.find(state: "parliament").sort(created_at : -1).run (err, arr) ->
      if err? then cb err, null else cb null, arr

  find_latest_petitions = (cb) ->
    col.find().sort(created_at : -1).run (err, arr) ->
      return if err? then cb err, null else cb null, arr

  remove_petition = (id, cb) ->
    return cb "invalid id", null if not is_valid_id id
    o_id = BSON.ObjectID.createFromHexString(id)
    col.find(_id: o_id).remove().run (err) ->
      if err? then cb err else cb null

  support_petition = (id, cb) ->
    return cb "invalid id", null if not is_valid_id id
    o_id = BSON.ObjectID.createFromHexString(id)
    q = col.find(_id: o_id).update $inc: support_votes: 1
    q.run (err) ->
      if err? then cb err else cb null

  set_petition_state = (id, state, cb) ->
    o_id = BSON.ObjectID.createFromHexString(id)
    q = col.find(_id: o_id).update $set: {state: state}
    q.run (err) ->
      if err? then cb err else cb null

  # --- demo state changes ---

  verify_VEVs = (id, cb) ->
    set_petition_state id, "vevs_approved", (err) ->
      return cb err if err?
      find_petition_by_id id, (err, petition) ->
        return cb err if err?
        email.send_notification_VEV_approval petition.name, settings.server.url + "/#/aloite/#{petition._id}", NOTIFICATION_EMAIL, cb

  support_petition_50k = (id, cb) ->
    o_id = BSON.ObjectID.createFromHexString(id)
    q = col.find(_id: o_id).update $set: {support_votes: 50000, state: "supported"}
    q.run (err) ->
      return cb err if err?
      find_petition_by_id id, (err, petition) ->
        return cb err if err?
        email.send_notification_50k petition.name, settings.server.url + "/#/aloite/#{petition._id}", NOTIFICATION_EMAIL, cb

  approve_petition_OM = (id, cb) ->
    set_petition_state id, "om_approved", cb

  send_to_OM = (id, cb) ->
    set_petition_state id, "om_verifying", cb

  approve_petition_VRK = (id, cb) ->
    set_petition_state id, "vrk_approved", cb

  send_to_VRK = (id, cb) ->
    set_petition_state id, "vrk_verifying", cb

  send_to_parliament = (id, cb) ->
    set_petition_state id, "parliament", cb

  # --- api ---

  app.get "/api/petitions", (req, res) ->
    find_petitions (err, json) ->
      if err? then res.send 500 else res.send json

  app.get "/api/petitions/latest", (req, res) ->
    find_latest_petitions (err, json) ->
      if err? then res.send 500 else res.send json

  app.get "/api/petitions/parliament", (req, res) ->
    find_petitions_in_parliament (err,arr) ->
      if err? then res.send 500 else res.send arr

  app.get "/api/petitions/votable", (req, res) ->
    find_votable_petitions (err, arr) ->
      if err? then res.send 500 else res.send arr

  app.get "/api/petitions/author/:author", (req, res) ->
    find_petitions_by_author req.params.author, (err, json) ->
      if err? then res.send 500 else res.send json

  app.post "/api/create_petition", (req, res) ->
    console.log "create_petition:"
    console.log req.body
    validate_petition req.body, (err) ->
      return res.send {err: err}, 422 if err?
      create_petition req.body, (err, id) ->
        return res.send 500 if err?
        res.send {id: id}, 200
        #demoflow: after petition has been created wait a while and then verify VEVs
        setTimeout () ->
            verify_VEVs id, (err) ->
              console.log "ERROR (verify_VEVs): #{err}" if err?
          ,VERIFY_VEVS_DELAY

  app.post "/api/support_petition_50k", (req, res) ->
    console.log req.body
    console.log req.params
    return res.send {err: "invalid petition id"}, 422 if not is_valid_id req.body.id
    authorize req.body.id, DEMO_USER, (err) ->
      return res.send 403 if err?
      support_petition_50k req.body.id, (err) ->
        if err? then res.send 500 else res.send 200

  app.get "/api/petition/:id", (req, res) ->
    return res.send {err: "invalid petition id"}, 422 if not is_valid_id req.params.id
    find_petition_by_id req.params.id, (err, json) ->
      return res.send 500 if err?
      return res.send 404 if not json?
      res.send json

  app.get "/api/petition/:id/approve_OM", (req, res) ->
    return res.send {err: "invalid petition id"}, 422 if not is_valid_id req.params.id
    authorize req.params.id, DEMO_USER, (err) ->
      return res.send 403 if err?
      approve_petition_OM req.params.id, (err) ->
        if err? then res.send 500 else res.send 200

  app.get "/api/petition/:id/send_OM", (req, res) ->
    return res.send {err: "invalid petition id"}, 422 if not is_valid_id req.params.id
    authorize req.params.id, DEMO_USER, (err) ->
      return res.send 403 if err?
      send_to_OM req.params.id, (err) ->
        if err? then res.send 500 else res.send 200

  app.get "/api/petition/:id/approve_VRK", (req, res) ->
    return res.send {err: "invalid petition id"}, 422 if not is_valid_id req.params.id
    authorize req.params.id, DEMO_USER, (err) ->
      return res.send 403 if err?
      approve_petition_VRK req.params.id, (err) ->
        if err? then res.send 500 else res.send 200

  app.get "/api/petition/:id/send_VRK", (req, res) ->
    return res.send {err: "invalid petition id"}, 422 if not is_valid_id req.params.id
    authorize req.params.id, DEMO_USER, (err) ->
      return res.send 403 if err?
      send_to_VRK req.params.id, (err) ->
        if err? then res.send 500 else res.send 200

  app.get "/api/petition/:id/send_to_parliament", (req, res) ->
    return res.send {err: "invalid petition id"}, 422 if not is_valid_id req.params.id
    authorize req.params.id, DEMO_USER, (err) ->
      return res.send 403 if err?
      send_to_parliament req.params.id, (err) ->
        if err? then res.send 500 else res.send 200

  app.get "/api/petition/:id/support", (req, res) ->
    return res.send {err: "invalid petition id"}, 422 if not is_valid_id req.params.id
    authorize req.params.id, DEMO_USER, (err) ->
      return res.send 403 if err?
      support_petition req.params.id, (err) ->
        if err? then res.send 500 else res.send 200

  app.get "/api/petition/:id/remove", (req, res) ->
    return res.send {err: "invalid petition id"}, 422 if not is_valid_id req.params.id
    authorize req.params.id, DEMO_USER, (err) ->
      return res.send 403 if err?
      remove_petition req.params.id, (err) ->
        if err? then res.send 500 else res.send 200
