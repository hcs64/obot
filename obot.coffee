level_cnv = document.getElementById('level')

prog_cnv = document.getElementById('program')
cont_cnv = document.getElementById('controls')

level_ctx = level_cnv.getContext('2d')
prog_ctx = prog_cnv.getContext('2d')
cont_ctx = cont_cnv.getContext('2d')

clear = (cnv, ctx) ->
  ctx.fillStyle = 'black'
  ctx.fillRect(0,0,cnv.width,cnv.height)

# level graphics
cell_size = 32
renderLevel = (level_ctx, prog_ctx) ->
  ctx = level_ctx
  ctx.save()

  # playfield
  ctx.lineWidth = .5
  ctx.strokeStyle = 'white'

  for xi in [1...10]
    ctx.beginPath()
    ctx.moveTo(xi*32+.5,0)
    ctx.lineTo(xi*32+.5,320)
    ctx.stroke()

  for yi in [1...10]
    ctx.beginPath()
    ctx.moveTo(0,yi*32+.5)
    ctx.lineTo(320,yi*32+.5)
    ctx.stroke()

  ctx.restore()

  # goal
  ctx.save()
  ctx.lineWidth = 1.5
  ctx.strokeStyle = 'white'
  ctx.save()

  ctx.translate(
    (@initial_bot_location.xi+.5) * cell_size,
    (@initial_bot_location.yi+.5) * cell_size)
  ctx.beginPath()
  ctx.arc(0, 0, cell_size*.4, 0, Math.PI)
  ctx.stroke()
  ctx.restore()

  # item
  @bot.has_item = true
  if !@bot.has_item
    ctx.translate( (@item_location.xi+.5)*cell_size,
                   (@item_location.yi+.5)*cell_size)
  else
    ctx.translate( (@bot.showxi+.5)*cell_size,
                   (@bot.showyi+.5)*cell_size)
  ctx.beginPath()
  ctx.arc(0,0,cell_size*.4,0,Math.PI,true)
  ctx.stroke()
  ctx.restore()


  # bot
  @bot.render(ctx)

  # commands
  ctx = prog_ctx
  for cmd, i in @commands
    col = i

    cur = (@show_current_command? and i == @show_current_command)
    row = 0
    renderCommand(ctx, cmd, (x: col*command_size, y: row*command_size),
      cur and (
        @mode == levelMode.FULLPLAYING or
        @mode == levelMode.TURNAROUND), false)

    cur = (@show_current_command? and i == @show_current_command)
    row = 1
    renderCommand(ctx, cmd, (x: col*command_size, y: row*command_size),
      cur and @mode == levelMode.REVPLAYING, true)

  if @commands.length > 0
    renderCommand(ctx, reverse_cmd,
      (x: @commands.length*command_size, y: .5*command_size),
      @show_current_command? and @commands.length == @show_current_command and
      @mode == levelMode.REVPLAYING)

  return

# bot graphics
hr3 = Math.sqrt(3)/2
rr3 = 1/Math.sqrt(3)
bot_size = cell_size*.75
bot_speed = 4 # cells per second
bot_points = [
  (x: bot_size * rr3, y: 0),
  (x: -bot_size * (hr3-rr3), y: -bot_size/2),
  (x: -bot_size * (hr3-rr3), y: bot_size/2)
]

renderBot = (ctx) ->
  bp = bot_points
  ctx.save()
  ctx.translate((@showxi + .5) * cell_size, (@showyi + .5) * cell_size)
  ctx.rotate(-@showdir)

  ctx.beginPath()
  ctx.moveTo(bp[0].x, bp[0].y)
  ctx.lineTo(bp[1].x, bp[1].y)
  ctx.lineTo(bp[2].x, bp[2].y)
  ctx.closePath()

  ctx.lineWidth = 1.5
  ctx.strokeStyle = 'white'
  ctx.fillStyle = 'black'

  ctx.fill()
  ctx.stroke()

  # "eye"
  ctx.beginPath()
  ctx.arc(bot_points[0].x, bot_points[0].y, bot_size/4,
    (1-1/5)*Math.PI, (1+1/5)*Math.PI)
  ctx.stroke()

  ctx.restore()

  return

# general directions
UP = (theta: Math.PI/2, dx: 0, dy: -1)
LEFT = (theta: Math.PI, dx: -1, dy: 0)
RIGHT = (theta: 0, dx: 1, dy: 0)
DOWN = (theta: -Math.PI/2, dx: 0, dy: 1)

reverseDir = (dir) ->
  switch dir
    when UP
      return DOWN
    when DOWN
      return UP
    when LEFT
      return RIGHT
    when RIGHT
      return LEFT

renderArrow  = (ctx, dir, size) ->
  as = size*.75  # arrow size
  ahs = size*.2 # arrowhead size

  ctx.rotate(-dir)

  ctx.beginPath()
  ctx.moveTo(-as/2, 0)
  ctx.lineTo(as/2, 0)
  ctx.lineTo(as/2-ahs,ahs)
  ctx.moveTo(as/2,0)
  ctx.lineTo(as/2-ahs,-ahs)
  ctx.stroke()

  return

# command graphics
command_size = 32
inner_command_size = 29
command_scrim_points = do ->
  ics = inner_command_size
  [
    (x: -ics/2, y: -ics/2),
    (x: -ics/2, y: +ics/2),
    (x: +ics/2, y: +ics/2),
    (x: +ics/2, y: -ics/2)
  ]

renderCommand = (ctx, what, where, current, rev = false) ->
  cs = command_size
  ics = inner_command_size

  ctx.save()
  
  ctx.lineWidth = 1.5
  ctx.strokeStyle = 'white'

  ctx.translate(where.x+.5*cs, where.y+.5*cs)

  ctx.strokeRect( -ics/2, -ics/2, ics, ics )

  if current
    ctx.fillStyle = 'white'
    for pt in command_scrim_points
      ctx.fillRect(pt.x-ics*.1, pt.y-ics*.1, ics*.2, ics*.2)
 
  what.render(ctx, rev)
  ctx.restore()

  return

# control panel button graphics
controls_start = (x: 10, y: 10)
control_size = 66
inner_control_size = 60
control_bevel = 6
renderControlPanel = (ctx) ->
  ctx.translate(controls_start.x, controls_start.y)

  for b, i in @buttons
    ctx.save()
    
    ctx.lineWidth = 1.5
    if i != @selected_button
      ctx.strokeStyle = 'white'
      ctx.fillStyle = 'black'
    else
      ctx.strokeStyle = 'black'
      ctx.fillStyle = 'white'

    renderButtonScrim(ctx)

    ctx.translate(inner_control_size/2,inner_control_size/2)
    b.render(ctx)
    ctx.restore()
    ctx.translate(0,control_size)

  return

clickControlPanel = (clickpos) ->
  x = controls_start.x
  y = controls_start.y

  for b, i in @buttons
    if clickpos.x > x and clickpos.y > y and
       clickpos.x < x+control_size and clickpos.y < y+control_size
      return [b, i]

    y = y + control_size

  return [null, -1]

renderButtonScrim = (ctx) ->
  ctx.save()

  ics = inner_control_size
  cb = control_bevel

  ctx.beginPath()
  ctx.moveTo(0, cb)
  ctx.lineTo(cb, 0)
  ctx.lineTo(ics-cb, 0)
  ctx.lineTo(ics, cb)
  ctx.lineTo(ics, ics-cb)
  ctx.lineTo(ics-cb, ics)
  ctx.lineTo(cb, ics)
  ctx.lineTo(0, ics-cb)
  ctx.closePath()
  
  ctx.fill()
  ctx.stroke()

  ctx.restore()

  return

renderPlayButton = (ctx) ->
  # reusing the bot triangle
  bp = bot_points

  ctx.beginPath()
  ctx.moveTo(bp[0].x, bp[0].y)
  ctx.lineTo(bp[1].x, bp[1].y)
  ctx.lineTo(bp[2].x, bp[2].y)
  ctx.closePath()

  ctx.stroke()

  return

renderUndoButton = (ctx) ->
  ics = inner_control_size*.35
  ctx.beginPath()

  ctx.moveTo(-ics,-ics)
  ctx.lineTo(ics,ics)
  ctx.moveTo(-ics,ics)
  ctx.lineTo(ics,-ics)

  ctx.stroke()
  return

# TODO: these should handle the passage of time? or maybe that is up to
# stepLevelSimulation?
moveCommand = (level) ->
  switch level.mode
    when levelMode.PLAYING, levelMode.FULLPLAYING
      level.bot.xi += @dir.dx
      level.bot.yi += @dir.dy
      level.bot.dir = @dir.theta
    when levelMode.REVPLAYING
      dir = reverseDir(@dir)
      level.bot.xi += dir.dx
      level.bot.yi += dir.dy
      level.bot.dir = dir.theta

noActionCommand = (level) ->
  return

arrowCommandRender = (ctx, rev) ->
  ics = inner_command_size * if rev then -1 else 1

  renderArrow(ctx, @dir.theta, ics)

reverseCommandRender = (ctx) ->
  ics  = inner_command_size

  ctx.beginPath()
  ctx.moveTo(-ics*.2, -ics*.3)
  ctx.lineTo(0, -ics*.3)
  ctx.arc(0,0,ics*.3, -Math.PI/2, Math.PI/2, false)

  ctx.lineTo(-ics*.2, ics*.3)
  ctx.lineTo(-ics*.1, ics*.15)
  ctx.moveTo(-ics*.2, ics*.3)
  ctx.lineTo(-ics*.1, ics*.45)

  ctx.stroke()

  return

up_arrow_cmd =
  render: arrowCommandRender
  dir: UP
  action: moveCommand
left_arrow_cmd =
  render: arrowCommandRender
  dir: LEFT
  action: moveCommand
right_arrow_cmd =
  render: arrowCommandRender
  dir: RIGHT
  action: moveCommand
down_arrow_cmd =
  render: arrowCommandRender
  dir: DOWN
  action: moveCommand

reverse_cmd =
  render: reverseCommandRender

# buttons

max_commands = 9

addCommandButtonAction = (level) ->
  if level.commands.length >= max_commands
    return false

  switch level.mode
    when levelMode.PLAYING, levelMode.FULLPLAYING
      level.commands[level.commands.length] = @cmd
    when levelMode.REVPLAYING, levelMode.TURNAROUND
      level.reset()
      level.commands[level.commands.length] = @cmd

  true

playButtonAction = (level) ->
  level.resetAndRun()
  level.mode = levelMode.FULLPLAYING
  return

undoButtonAction = (level) ->
  if level.commands.length == 0
    return false

  level.commands = level.commands[...-1]

  if level.mode == levelMode.STOP
    level.reset()
    return true

  if level.current_command >= level.commands.length or
     level.mode != levelMode.PLAYING
    level.resetAndRun()
    while level.step()
      true

arrowButtonRender = (ctx) ->
  renderArrow(ctx, @dir.theta, inner_control_size)

go_up_button =
  render: arrowButtonRender
  dir: UP
  cmd: up_arrow_cmd
  action: addCommandButtonAction
go_left_button =
  render: arrowButtonRender
  dir: LEFT
  cmd: left_arrow_cmd
  action: addCommandButtonAction
go_right_button =
  render: arrowButtonRender
  dir: RIGHT
  cmd: right_arrow_cmd
  action: addCommandButtonAction
go_down_button =
  render: arrowButtonRender
  dir: DOWN
  cmd: down_arrow_cmd
  action: addCommandButtonAction
play_button =
  render: renderPlayButton
  action: playButtonAction
undo_button =
  render: renderUndoButton
  action: undoButtonAction

# level

levelMode =
  PLAYING: 2
  FULLPLAYING: 3
  TURNAROUND: 4
  REVPLAYING: 5

levelAnimMode =
  READY: 1  # ready to run the next command
#  TURNING: 2  # animating turn
  MOVING: 3 # animating movement
  DONE: 4   # end of the program

resetLevel = ->
  @bot.showxi = @bot.xi = @initial_bot_location.xi
  @bot.showyi = @bot.yi = @initial_bot_location.yi
  @bot.showdir = @bot.dir = @initial_bot_location.dir

  @mode = levelMode.PLAYING
  @current_command = 0

  return

resetAndRunLevel = ->
  @reset()
  @mode = levelMode.PLAYING
  @last_t = Date.now()/1000
  @animation_mode = levelAnimMode.READY
  delete @move_control

  return

lerp = (t, x0, x1) ->
  if t < 0
    t = 0
  if t > 1
    t = 1
  (x1-x0)*t + x0

animateLevel = (t) ->
  #console.log("mode = " + @mode + " animMode = " + @animation_mode)

  if @animation_mode == levelAnimMode.READY
    if @mode == levelMode.PLAYING
      @show_current_command = null
    else
      @show_current_command = @current_command
    @bot.showxi = @bot.xi
    @bot.showyi = @bot.yi
    @bot.showdir = @bot.dir

    next_move_control =
      start: (t: t, x: @bot.xi, y: @bot.yi, dir: @bot.dir)
      duration: 1/bot_speed
    if @step()
      @move_control = next_move_control
      @animation_mode = levelAnimMode.MOVING

  # immediately run this if we switched to MOVING above
  if @animation_mode == levelAnimMode.MOVING
    rel_t = (t-@move_control.start.t)/@move_control.duration
    @bot.showxi = lerp rel_t, @move_control.start.x, @bot.xi
    @bot.showyi = lerp rel_t, @move_control.start.y, @bot.yi
    @bot.showdir = @bot.dir

    if rel_t >= 1
      @animation_mode = levelAnimMode.READY

  @last_t = t

  return

stepLevelSimulation = ->
  if @commands.length == 0 and @mode == levelMode.FULLPLAYING
    @mode = levelMode.PLAYING

  if @current_command != null &&
     @current_command >= 0 &&
     @current_command < @commands.length
    # TODO: errors for bad movement
    @commands[@current_command].action(this)

    @advanceCurrentCommand()

    if @mode == levelMode.FULLPLAYING &&
       @current_command == @commands.length
      @mode = levelMode.TURNAROUND
    return true
  else if @mode == levelMode.TURNAROUND
    @mode = levelMode.REVPLAYING
    @advanceCurrentCommand()
    return true
  else
    return false


setupLevel = (initial_bot_location, item_location) ->
  o =
    initial_bot_location: initial_bot_location
    item_location: item_location
    bot: (render: renderBot)
    commands: [ ]
    current_command: 0
    render: renderLevel
    animate: animateLevel
    step: stepLevelSimulation

    mode: levelMode.PLAYING
    animation_mode: levelAnimMode.READY

    advanceCurrentCommand: ->
      switch @mode
        when levelMode.PLAYING, levelMode.FULLPLAYING
          @current_command++
        when levelMode.REVPLAYING
          @current_command--
    reset: resetLevel
    resetAndRun: resetAndRunLevel
  o.reset()
  o

# control panel
setupControlPanel = ->
  buttons: [ play_button, undo_button,
            go_up_button, go_down_button, go_left_button, go_right_button ]
  selected_button: null
  render: renderControlPanel
  click: clickControlPanel

control_panel = setupControlPanel()
level_state = setupLevel((xi:0, yi:5, dir:0), (xi:6, yi:5))

stop = false

render = ->
  t = Date.now()/1000

  clear(level_cnv, level_ctx)
  clear(prog_cnv, prog_ctx)

  level_state.animate(t)
  level_state.render(level_ctx, prog_ctx)

  #stop = true
  
  if !stop
    requestAnimationFrame(render)

requestAnimationFrame(render)

# interface
cont_cnv.addEventListener 'click', (ev) ->
  pos = getCursorPosition(cont_cnv, ev)

  [button, index] = control_panel.click(pos)
  if button
    button.action(level_state)

clear(cont_cnv, cont_ctx)
control_panel.render(cont_ctx)

