exec   = require('child_process').exec
mailer = require('mailer')

SIGNATURE = "\n\nTerveisin,\nAloitepalvelu, Oikeusministeriö"

notification_VEV_approval = (petition_title, petition_url) ->
  subject: "Vireillepanijat, edustajat ja varaedustajat ovat liittyneet aloitteelle"
  body:
    """
    Kaikki vireillepanijat, edustajat ja varaedustajat ovat hyväksyneet kutsusi liittyä aloitteelle ”#{petition_title}”. Voit nyt edetä lähettämään aloitteen Oikeusministeriölle tarkistettavaksi oheisesta linkistä: #{petition_url}
    """
notification_50k = (petition_title, petition_url) ->
  subject: "Aloitteellesi on kertynyt vaaditut 50 000 kannatusilmoitusta"
  body:
    """
    Aloitteellesi "#{petition_title}" on kertynyt 50 000 kannatusilmoitusta. Voit nyt edetä lähettämään kannattajalistan Väestörekisterikeskukselle tarkastettavaksi oheisesta linkistä: #{petition_url}
    """

send_mail = () -> #uninitialized
exports.init_emailsender = (settings, app, db) ->

  send_mail = (recipient,subject,body,cb) ->
    return cb null #remove this to enable email sending

    # Settings for mailer
    mailer.send
        host : ""                        # smtp server hostname
        port : ""                        # smtp server port
        ssl: true                        # for SSL support - REQUIRES NODE v0.3.x OR HIGHER
        domain : settings.server.host    # domain used by client to identify itself to server
        to : recipient
        from : "info@aloitepalvelu.fi"
        subject : subject
        body: body + SIGNATURE
        authentication : "login"         # auth login is supported; anything else is no auth
        username : "USERNAME"            # username
        password : "PASSWORD"            # password
      , cb

exports.send_notification_VEV_approval = (petition_title, petition_url, recipient, cb) ->
  console.log "sending email: notification_VEV_approval to #{recipient}"
  email = notification_VEV_approval petition_title, petition_url
  send_mail recipient, email.subject, email.body, cb

exports.send_notification_50k = (petition_title, petition_url, recipient, cb) ->
  console.log "sending email: notification_50k to #{recipient}"
  email = notification_50k petition_title, petition_url
  send_mail recipient, email.subject, email.body, cb
