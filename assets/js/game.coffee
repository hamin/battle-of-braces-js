client = new Faye.Client('/faye')

$(document).ready () ->
  # Faye Sub - Opponent Position
  client.subscribe "/opponentPos", (message) ->
    console.log "Opponent Moved!"
  
  # Faye Sub - Fire
  client.subscribe "/fire", (message) ->
    if message.oppClientId isnt clientId
      shoot {x: message.x, y: message.y}, true
      
  
  # Arrow Button Bindings
	$('body').keydown (event) ->
	  console.log "keyCode #{event.keyCode}"
	  curLeftPos = $(".me").offset().left
	  curTopPos = $(".me").offset().top

	  offset = 50
	  #left
	  if event.keyCode is 37
	    updateDivPosition "me", curLeftPos - offset
	  # right
	  if event.keyCode is 39 	
      updateDivPosition "me", curLeftPos + offset
    if event.keyCode is 16
      shoot {x: curLeftPos+50, y: curTopPos-15}, false
      oppY = $('.opponent').offset().top + $('.opponent').height()
      client.publish '/fire', x: curLeftPos+50, y: oppY, oppClientId: clientId

    client.publish "/opponentPos", { curLeftPos: $(".me").offset().left }    
	

# copied from RaphaelJS Polar Clock example
# http://raphaeljs.com/polar-clock.html
window.onload = ->
  updateVal = (value, total, R, hand, id) ->
    if total is 31
      d = new Date
      d.setDate 1
      d.setMonth d.getMonth() + 1
      d.setDate -1
      total = d.getDate()
    color = "hsb(#{Math.round(R) / 200}, #{value / total}, .75)"
    if init
      hand.animate
        arc: [ value, total, R ], 900, ">"
    else
      if not value or value is total
        value = total
        hand.animate
          arc: [ value, total, R ], 750, "bounce", ->
          hand.attr arc: [ 0, total, R ]
      else
        hand.animate
          arc: [ value, total, R ], 750, "elastic"
    html[id].innerHTML = (if value < 10 then "0" else "") + value
    html[id].style.color = Raphael.getRGB(color).hex
  drawMarks = (R, total) ->
    if total is 31
      d = new Date
      d.setDate 1
      d.setMonth d.getMonth() + 1
      d.setDate -1
      total = d.getDate()
    color = "hsb(".concat(Math.round(R) / 200, ", 1, .75)")
    out = r.set()
    value = 0

    while value < total
      alpha = 360 / total * value
      a = (90 - alpha) * Math.PI / 180
      x = 300 + R * Math.cos(a)
      y = 300 - R * Math.sin(a)
      out.push r.circle(x, y, 2).attr(marksAttr)
      value++
    out
  r = Raphael("holder", 600, 600)
  R = 200
  init = true
  param =
    stroke: "#fff"
    "stroke-width": 30

  hash = document.location.hash
  marksAttr =
    fill: hash or "#444"
    stroke: "none"

  html = [ document.getElementById("h"), document.getElementById("m"), document.getElementById("s"), document.getElementById("d"), document.getElementById("mnth"), document.getElementById("ampm") ]
  r.customAttributes.arc = (value, total, R) ->
    alpha = 360 / total * value
    a = (90 - alpha) * Math.PI / 180
    x = 300 + R * Math.cos(a)
    y = 300 - R * Math.sin(a)
    color = "hsb(".concat(Math.round(R) / 200, ",", value / total, ", .75)")
    path = undefined
    if total is value
      path = [ [ "M", 300, 300 - R ], [ "A", R, R, 0, 1, 1, 299.99, 300 - R ] ]
    else
      path = [ [ "M", 300, 300 - R ], [ "A", R, R, 0, +(alpha > 180), 1, x, y ] ]
    path: path
    stroke: color

  drawMarks R, 60
  sec = r.path().attr(param).attr(arc: [ 0, 60, R ])
  R -= 40
  drawMarks R, 60
  min = r.path().attr(param).attr(arc: [ 0, 60, R ])
  R -= 40
  drawMarks R, 12
  hor = r.path().attr(param).attr(arc: [ 0, 12, R ])
  R -= 40
  drawMarks R, 31
  day = r.path().attr(param).attr(arc: [ 0, 31, R ])
  R -= 40
  drawMarks R, 12
  mon = r.path().attr(param).attr(arc: [ 0, 12, R ])
  pm = r.circle(300, 300, 16).attr(
    stroke: "none"
    fill: Raphael.hsb2rgb(15 / 200, 1, .75).hex
  )
  html[5].style.color = Raphael.hsb2rgb(15 / 200, 1, .75).hex
  (->
    d = new Date
    am = (d.getHours() < 12)
    h = d.getHours() % 12 or 12
    updateVal d.getSeconds(), 60, 200, sec, 2
    updateVal d.getMinutes(), 60, 160, min, 1
    updateVal h, 12, 120, hor, 0
    updateVal d.getDate(), 31, 80, day, 3
    updateVal d.getMonth() + 1, 12, 40, mon, 4
    pm[(if am then "hide" else "show")]()
    html[5].innerHTML = (if am then "AM" else "PM")
    setTimeout arguments.callee, 1000
    init = false
  )()
