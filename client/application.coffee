petitionFormTemplate = null

setProgress = (el, current) ->
  limit = 50000
  pb = el.find('.progress-bar')
  g = el.find '.green'
  collected = el.find('.collected .amount').text current
  needed = el.find('.needed .amount').text (limit - current)
  g.width Math.floor((pb.width() - 2) * (current/limit))
  g.width (pb.width() - 2) if (g.width() > pb.width() - 2)

beforeRender = () ->
  $('.page').hide()
  $('#main').show()
  $('#footer').show()


datePickerOptions =
  firstDay: 1
  dateFormat: 'dd.mm.yy'
  showOn: 'both'
  defaultDate: null
  #maxDate: new Date()
  buttonImageOnly: true
  buttonImage: '/img/calendar-icon.png'
  monthNames: ['Tammikuu', 'Helmikuu', 'Maaliskuu', 'Huhtikuu', 'Toukokuu', 'Kesäkuu', 'Heinäkuu', 'Elokuu', 'Syyskuu', 'Lokakuu', 'Marraskuu', 'Joulukuu']
  dayNamesMin: ['Su', 'Ma', 'Ti', 'Ke', 'To', 'Pe', 'La']

createUploader = (id) ->
  uploader = new qq.FileUploader {
    element: document.getElementById(id)
    action: '/uploader/upload-success.html'
    debug: false
    onComplete: (fid, file, response) ->
      el = $('#' + id)
      input = $('<input type="hidden">').attr('name', el.attr('data-name') + '[]').val file
      el.append input
  }

validateEmail = (email) ->
  re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
  return re.test email

initFormUI = () ->
  $('.ui-form .field.radio').each () ->
    $(this).find('input[type=radio]').change () ->
      $(this).parent('label').toggleClass('selected', $(this).attr 'selected').siblings().removeClass 'selected'

  $('.ui-form .email-field').each () ->
    field = $(this)
    name = field.attr('data-name')
    ul = $('<ul class="emails" />')
    inputBox = $('<div class="email-input" />')
    input = $('<textarea rows="2" />')

    unifyHeights = () ->
      h = 0
      fields = field.siblings('.email-field').add(field)
      fields.each () ->
        ip = $(this).find '.email-input'
        ip.css 'height', 'auto'
        h = ip.height() if ip.height() > h
      fields.each () ->
        $(this).find('.email-input').height h

    parseEmails = (e = null, blur = false) ->
      val = input.val()
      emails = val.split(/[\s\n\t\v,]+/)
      if emails.length > 1 or blur
        $.each emails, (k, email) ->
          email = $.trim(email)
          if validateEmail email
            li = $('<li />').text(email)
            x = $('<a href="#" class="remove">x</a>')
            hid = $('<input type="hidden" />').attr('name', name + '[]').val email
            field.append hid
            x.click () ->
              x.parent().remove()
              hid.remove()
              unifyHeights()
              return false
            li.append x
            ul.append li
            emails.splice k, 1
            unifyHeights()


        input.val $.trim emails.join ' '
    input.keydown (e) ->
      if (input.val()).length == 0 && e.keyCode == 8
        ul.find('li').last().remove()
        field.find('input[type=hidden]').last().remove()
      if e.keyCode == 13
        parseEmails(e)
    input.keyup (e) -> parseEmails(e)
    input.blur (e) -> parseEmails(e, true)
    inputBox.append ul
    inputBox.append input
    inputBox.click () ->
      input.focus()
    field.append inputBox

  lawReference = $('.law_reference:first').clone()
  referenceIndex = 1
  $('.clone_btn').click () ->
    ref = lawReference.clone()
    ref.find('input').each () ->
      $(this).attr 'name', (($(this).attr('name')).replace '0', referenceIndex)
    referenceIndex++
    ref.insertAfter('.law_reference:last')



  $('.ui-form .keyword-field').each () ->
    field = $(this)
    name = field.attr('data-name')
    inputBox = $('<div class="keyword-input" />')
    input = $('<textarea rows=1 />')

    parseKeywords = (e = null, blur = false) ->
      val = input.val()
      keywords = val.split(/[\s\n\t\v,]+/)
      if keywords.length > 1 or blur
        $.each keywords, (k, keyword) ->
          keyword = $.trim(keyword)
          if keyword.length > 0
            kw = $('<span class="keyword" />').text(keyword)
            x = $('<a href="#" class="remove">x</a>')
            hid = $('<input type="hidden" />').attr('name', name + '[]').val keyword
            field.append hid
            x.click () ->
              x.parent().remove()
              hid.remove()
              return false
            kw.append x
            kw.insertBefore input
            keywords.splice k, 1

        input.val $.trim keywords.join ' '
    input.keydown (e) ->
      if (input.val()).length == 0 && e.keyCode == 8
        inputBox.find('.keyword').last().remove()
        field.find('input[type=hidden]').last().remove()
    input.keyup (e) -> parseKeywords(e)
    input.blur (e) -> parseKeywords(e, true)
    inputBox.append input
    inputBox.click () ->
      input.focus()
    field.append inputBox


  $('form .attachments').each () ->
    createUploader $(this).attr 'id'

  $('.field.date input').datepicker(datePickerOptions)

  $('#submit-add-form').unbind('click').click () ->
    #console.log $(this).prev('form').serializeArray()
    form = $('#newpetitionform')
    form.find('.field.date input').each () ->
      d = ($(this).val()).split(".")
      if d.length == 3
        $(this).val(d[2] + '-' + d[1] + '-' + d[0])
    send = $.post '/api/create_petition', form.serialize(), (data, status, XHR) ->
      #console.log status
      if status == 'success'
        Spine.Route.navigate '/aloite/' + data.id
    send.error () ->
      $('#uusi-aloite .ui-form .validation-error').slideDown(200)
    return false

runProgress = (p, petition_id) ->
  pb = p.find('.progress-bar')
  g = pb.find '.green'
  collected = p.find('.collected .amount')
  collected.text '0'
  needed = p.find('.needed .amount').text '50000'

  c = 0
  rmin = 0
  rmax = 20
  runIt = ->
    limit = 50000
    random = Math.floor(Math.random() * (rmax - rmin + 1)) + rmin;
    c = c + random
    c = limit if (c > limit)
    collected.text c
    needed.text if c <= limit then limit - c else 0

    g.width Math.floor((pb.width() - 2) * (c/limit))
    g.width (pb.width() - 2) if (g.width() > pb.width() - 2)
    rmax = if c <= limit then rmax * 1.01 else Math.ceil(rmax * 0.8)

    if c >= limit
      $.post '/api/support_petition_50k', {id: petition_id}, (data, status) ->
        if status == 'success'
          $('.button-row.supported').show()
          $('.notification.supports_full').show()
    else
      setTimeout runIt, 60

  setTimeout runIt, 5000
  g.width 0

renderIndex = () ->
  beforeRender()
  $('#etusivu').show()
  getOwnedPetitions (err, ownedpetitions) ->
    $('.ownedpetitions').render(ownedpetitions[0..4], {'title@href': -> @url}) unless err?
  getVotablePetitions (err, votablepetitions) ->
    $('.votablepetitions').render(votablepetitions[0..2], {'title@href': -> @url}) unless err?
  getParliamentPetitions (err, parliamentpetitions) ->
    $('.parliamentpetitions').render(parliamentpetitions[0..2], {'title@href': -> @url}) unless err?
  false

renderAddForm = (params) ->
  beforeRender()
  if petitionFormTemplate?
    $('#newpetitionform').replaceWith(petitionFormTemplate.clone())
    initFormUI()
    $('#uusi-aloite').show()
  else
    Spine.Route.navigate '/kansalaisaloite'
  false

initiatorsPending = () ->
    $('.initiator').removeClass 'confirmed'
    $('.initiator').addClass 'pending'

setAttachmentTypeIcons = () ->
  #console.log $('.attachments a')
  $('.attachments a').each () ->
    $this = $(this)
    fn    = $this.text()
    $this.removeClass('link').addClass('pdf') if fn.match /\.pdf$/
    $this.removeClass('link').addClass('doc') if fn.match /\.doc$/

renderPetition = (params) ->
  return Spine.Route.navigate("/kansalaisaloite", true) if not params?.match[1]?
  beforeRender()
  $('.state_variation').hide()
  $('#aloite').show()
  url = '/api/petition/' + params.match[1]
  #console.log url
  directives =
    law_references:
      ref_num : -> if "#{@reference_number}#{@reference_year}" == "" then "" else "#{@reference_number} / #{@reference_year}"
      ref_name: -> @reference_name || ""
      ref_sec : -> if "#{@reference_section}#{@reference_momentum}" == "" then "" else "#{@reference_section} § / #{@reference_momentum}.momentti"
      'ref_url@href' : -> @reference_url || ""
      ref_url : -> @reference_url || ""
  $.get url, (petition) ->
    $('#aloite').render(petition, directives)
    $('#aloite .rationale').html petition["rationale"].replace(/\n/g, '<br> \n')
    $('#aloite .law_proposal').html petition["law_proposal"].replace(/\n/g, '<br> \n')

    if !loggedIn() and (petition.state == 'draft' or petition.state == 'vevs_approved' or petition.state == 'om_verifying')
      $('#modal-aloite').show()
      $('#modal-aloite .continue').unbind('click').click () ->
        Spine.Route.navigate '/vetuma-aloite/' + petition._id
        $('#modal-aloite').hide()
        return false
      $('#modal-aloite .cancel').unbind('click').click () ->
        Spine.Route.navigate '/kansalaisaloite'
        $('#modal-aloite').hide()
        return false

    $('#petition_author').text petition.author
    if $('#aloite ul.keywords').length == 1 and $('#aloite ul.keywords li').first().text() == ''
      $('#aloite ul.keywords').add($('#aloite ul.keywords').prev('h4')).hide()
    else
      $('#aloite ul.keywords').add($('#aloite ul.keywords').prev('h4')).show()

    if petition.law_proposal_attachments?
      $('#aloite .law_proposal_attachments').next('.virus-check-ok').show()
    else
      $('#aloite .law_proposal_attachments').next('.virus-check-ok').hide()

    if petition.rationale_attachments?
      $('#aloite .rationale_attachments').next('.virus-check-ok').show()
    else
      $('#aloite .rationale_attachments').next('.virus-check-ok').hide()
    setAttachmentTypeIcons()
    initiatorsPending() if petition.state == 'draft'
    $(".#{petition.state}").show()
    #Must be run AFTER rendering with transparency:
    if petition.state == 'draft'
      setTimeout () ->
          renderPetition params
        , 10000
    if petition.state == 'om_verifying'
      $('#aloite .petition-phases .phase:lt(2) .indicator').addClass('done')
      $('.notification.om_verifying').show()
    if petition.state == 'om_approved'
      $('#aloite .petition-phases .phase:lt(3) .indicator').addClass('done')
      if petition.author == "Petteri Roponen"
        runProgress $('#aloite .petition-progress'), petition._id
      else
        setProgress $('#aloite .petition-progress'), petition.support_votes
    else
      setProgress $('#aloite .petition-progress'), petition.support_votes

    if petition.state == 'supported'
      setProgress $('#aloite .petition-progress'), 50000
      $('#aloite .petition-phases .phase:lt(3) .indicator').addClass('done')
      $('.notification').hide()

    if petition.state == 'vrk_approved'
      setProgress $('#aloite .petition-progress'), 50000
      $('.button-row.parliament').show()
      $('#aloite .petition-phases .phase:lt(4) .indicator').addClass('done')
      $('.notification').hide()

    if petition.state == 'parliament'
      setProgress $('#aloite .petition-progress'), 50000
      $('#aloite .petition-phases .phase:lt(5) .indicator').addClass('done')
      $('.button-row.parliament').hide()
      $('.notification').hide()
      $('.notification.parliament').show()

    $('#send_OM').unbind('click').click () ->
      $.get url + '/send_OM', (data, status) ->
        if status == 'success'
          $('.button-row.vevs_approved').hide()
          $('.notification.om_verifying').show()
          $('#aloite .petition-phases .phase:lt(2) .indicator').addClass('done')

          setTimeout () ->
            $.get url + '/approve_OM', (data, status) ->
              $('#aloite .petition-phases .phase:lt(3) .indicator').addClass('done')
              runProgress $('#aloite .petition-progress'), petition._id
              $('.notification.om_verifying').hide()
          , 1000
      return false


    $('#send_VRK').unbind('click').click () ->
      $.get url + '/send_VRK', (data, status) ->
        if status == 'success'
          $('.button-row.supported').hide()
          $('.notification.vrk_verifying').show()
          $('#aloite .petition-phases .phase:lt(4) .indicator').addClass('done')

          setTimeout () ->
            $.get url + '/approve_VRK', (data, status) ->
              $('.notification.supports_full').hide()
              $('.notification.vrk_verifying').hide()
              $('.button-row.parliament').show()
          , 5000
      return false

    $('#send_to_parliament').unbind('click').click () ->
      $.get url + '/send_to_parliament', (data, status) ->
        if status == 'success'
          $('.button-row.parliament').hide()
          $('.notification.parliament').show()
          $('#aloite .petition-phases .phase:lt(5) .indicator').addClass('done')
      return false
    exp = $('.date.expiration')
    expd = new Date(exp.text())
    expd.setMonth( expd.getMonth() + 6 );
    #exp.text expd.getDate() + '.' + (expd.getMonth() + 1) + '.' + expd.getFullYear() + ' '
    exp.text '19.06.2011'
  false

renderSupport = (params) ->
  beforeRender()
  $('#kannatus').show()
  $('#kannatus .button-row .submit').unbind('click').click () ->
    $('#modal-kannatus').show()
    return false
  false

localizePetitionStatus = (state) ->
  localized_states =
    draft        : "vedos"
    vevs_approved: "vedos"
    om_verifying : "sisällön tarkastus"
    om_approved  : "julkaistu"
    supported    : "kannatettu"
    vrk_verifying: "kannattajalistan tarkastus"
    vrk_approved : "hyväksytty"
    parliament   : "eduskunta"
  return localized_states[state] || state

parsePetitionsList = (petitions) ->
  $.map petitions, (petition) ->
    pvm = new Date(petition.created_at)
    pvm = "#{pvm.getDate()}.#{pvm.getMonth()+1}.#{pvm.getFullYear()}"
    url    : "/#/aloite/#{petition._id}"
    date   : pvm
    title  : petition.name || "ei otsikkoa"
    status : localizePetitionStatus(petition.state)

getOwnedPetitions = (cb) ->
  $.get '/api/petitions/author/Petteri%20Ruponen', (petitions) ->
    cb null, parsePetitionsList petitions

getLatestPetitions = (cb) ->
  $.get '/api/petitions/latest', (petitions) ->
    petitions = parsePetitionsList petitions
    petitions = $.map petitions, (p) ->
      p["title"] = if p["title"].length > 49 then p["title"].substr(0,49) + '...' else p["title"]
      p
    cb null, petitions

getVotablePetitions = (cb) ->
  $.get '/api/petitions/votable', (petitions) ->
    petitions = parsePetitionsList petitions
    petitions = $.map petitions, (p) ->
      p["title"] = if p["title"].length > 49 then p["title"].substr(0,49) + '...' else p["title"]
      p
    cb null, petitions

getParliamentPetitions = (cb) ->
  $.get '/api/petitions/parliament', (petitions) ->
    petitions = parsePetitionsList petitions
    petitions = $.map petitions, (p) ->
      p["title"] = if p["title"].length > 49 then p["title"].substr(0,49) + '...' else p["title"]
      p
    cb null, petitions

renderLogged = () ->
  beforeRender()
  $('#etusivu-kirjautunut').show()
  getOwnedPetitions (err, ownedpetitions) ->
    $('.ownedpetitions').render(ownedpetitions, {'title@href': -> @url}) unless err?
  false

renderVetuma = () ->
  beforeRender()
  $('#vetuma').show().find('.overlay').show()
  $('#main').hide()
  $('#footer').hide()
  $('#vetuma .submit input').unbind('click').click () ->
    handleLogIn $('#vetuma input.username').val()
    Spine.Route.navigate "/uusi-aloite"
    return false
  false

renderVetumaKannatus = () ->
  beforeRender()
  $('#vetuma').show().find('.overlay').show()
  $('#main').hide()
  $('#footer').hide()
  $('#vetuma .submit input').unbind('click').click () ->
    handleLogIn $('#vetuma input.username').val()
    $('#kannatus .notification').show()
    $('#kannatus .button-row').hide()
    $('#kannatus').find('.collected .amount').text(parseInt($('#kannatus').find('.collected .amount').text()) + 1)
    $('#kannatus').find('.needed .amount').text(parseInt($('#kannatus').find('.needed .amount').text()) - 1)
    Spine.Route.navigate "/kannatus"
    return false
  false


renderVetumaAloite = (petition_id) ->
  beforeRender()
  $('#vetuma').show().find('.overlay').show()
  $('#main').hide()
  $('#footer').hide()
  $('#vetuma .submit input').unbind('click').click () ->
    handleLogIn $('#vetuma input.username').val()
    Spine.Route.navigate "/aloite/" + petition_id
    return false
  false

Controller =
  index: () ->
    renderIndex()
  redirect: () ->
    Spine.Route.navigate "/kansalaisaloite", true
  aloite: (params) ->
    renderPetition params
  uusiAloite: (params) ->
#    return Spine.Route.navigate("/vetuma", true) if not loggedIn()
    renderAddForm params
  kannatus: (params) ->
    renderSupport params
  kirjautunut: () ->
#    return Spine.Route.navigate("/vetuma", true) if not loggedIn()
    renderLogged()
  vetuma: (params) ->
    renderVetuma(params)
  vetumaKannatus: () ->
    renderVetumaKannatus()
  vetumaAloite: (params) ->
    renderVetumaAloite(params.match[1])

loggedIn = () ->
  if $('#logout').is(":visible") then true else false

handleLogIn  = (name = null) ->
  if(name?)
    $('#logout .user').text name
  else
    $('#logout .user').text $('#login input.user').val()
  $('#login').hide()
  $('#logout').show()
  $('body').addClass('logged')
  false

handleLogOut = () ->
  $('#logout').hide()
  $('#login .user').val('')
  $('#login').show()
  $('body').removeClass('logged')
  Spine.Route.navigate '/kansalaisaloite'
  false

updateLawSuggestions = (input, value) ->
  $input = $(input)
  $div   = $input.closest('div')
  value  = $.trim(value).toLowerCase().replace(/\s+/," ")
  filter = value.split(" ").join(".*")
  regexp = new RegExp filter, "i"

  updateLawRef = (law) ->
    $div.find('.lawsuggestions').remove()
    $div.find('.lawnum').val law.num
    $div.find('.lawyear').val law.year
    $div.find('.lawname').val law.name
    $link = $("<a>").attr('href', law.link).attr('target', '_blank').addClass('lawreflink lawsuggestions').text law.link
    $link.appendTo $div

    $input = $('<input type="hidden"/>').attr('name', 'law_references[' + ($div.index() - 1) + '][reference_url]').attr 'value', law.link
    $input.appendTo $div

  $div.find('.lawsuggestions').remove()
  return if filter == ""
  suggestions = []
  for law in lawsIndex
    suggestions.push law if regexp.test(law.name.toLowerCase()) or regexp.test(law.common_name.toLowerCase())

  if suggestions.length > 0
    $select_suggestion = $("<div/>").addClass 'lawsuggestions'
    $select_suggestion.appendTo $div
    for row in suggestions[0..5]
      $suggestionrow = $("<div><div class='number'>#{row.num}/#{row.year}</div><div class='name'> #{row.name} (#{row.common_name})</div></div>").addClass 'lawsuggestion'
      $select_suggestion.append $suggestionrow
      $suggestionrow.click do (row) -> () -> updateLawRef(row)

lawsIndex = []

$(document).ready ->
  Spine.Route.add
    ""                 : Controller.redirect
    "/kansalaisaloite" : Controller.index
    "/someview"    : Controller.someview
    "/aloite/:id"  : Controller.aloite
    "/uusi-aloite" : Controller.uusiAloite
    "/kannatus"    : Controller.kannatus
    "/kirjautunut" : Controller.kirjautunut
    "/vetuma"      : Controller.vetuma
    "/vetuma-kannatus"      : Controller.vetumaKannatus
    "/vetuma-aloite/:id"      : Controller.vetumaAloite
  Spine.Route.setup()

  petitionFormTemplate = $('#newpetitionform').clone()

  $('#login').submit handleLogIn
  $('#logout').submit handleLogOut
  $('a.dummy, input.dummy').live 'click', (e) ->
    e.preventDefault()
    return false

  $('#modal a.cancel').click () ->
    $('#modal').hide()
    return false

  $('#modal-kannatus a.cancel').click () ->
    $('#modal-kannatus').hide()
    return false

  $('#modal a.continue').click () ->
    $('#modal').hide()
    Spine.Route.navigate "/vetuma"
    return false

  $('#modal-kannatus a.continue').click () ->
    $('#modal-kannatus').hide()
    Spine.Route.navigate "/vetuma-kannatus"
    return false

  $('#vetuma .overlay').click () ->
    $(this).hide()
    return false

  $('a[href="/#/uusi-aloite"]').click () ->
    if not loggedIn()
      $('#modal').show()
      return false

  $('.qq-upload-remove').live 'click', () ->
    li = $(this).parent('li')
    index = li.index()
    li.parents('.attachments').find('input[type="hidden"]').eq(index).remove()
    li.remove()
    return false

  $.get '/api/laws', (laws) -> lawsIndex = laws

  $('.law_reference input.lawname').live 'keyup', (e) ->
    updateLawSuggestions $(this), $(this).val() if e.keyCode != 40 and e.keyCode != 38 and e.keyCode != 13
  $('.law_reference input.lawname').live 'keydown', (e) ->
    if e.keyCode == 40 or e.keyCode == 38
      current = $('.lawsuggestion.active')
      if e.keyCode == 40
        if current.length == 0
          $('.lawsuggestions:visible .lawsuggestion').first().addClass('active')
        else
          current.removeClass('active').next('.lawsuggestion').addClass('active')
      else if e.keyCode == 38
        if current.length == 0
          $('.lawsuggestions:visible .lawsuggestion').last().addClass('active')
        else
          current.removeClass('active').prev('.lawsuggestion').addClass('active')
    if e.keyCode == 13
      $('.lawsuggestion.active').click()
      e.stopPropagation()
      e.preventDefault()
      return false

  $('#disclaimer-trigger, #top-disclaimer a').click () ->
    $('#modal-disclaimer').show()
    false
  $('#modal-disclaimer .button').click () ->
    $('#modal-disclaimer').hide()
