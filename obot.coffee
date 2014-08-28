###
Interface rules

0. Initially in mode STOP

1. If you click a command, the command should be added to the list
STOP: enter mode PLAY
STOPDONE: reset and enter mode PLAY

exception A: not during TURNAROUND or PLAYREV
exception B: list is full, show error sparks on command list

2. If you click play, playback should reset and enter mode PLAYFWD

3. If you click undo, last command should be removed from the list,
   playback reset and fast-forwarded to the new last command, enter mode STOP

4. At the start of a command cycle
PLAY: advance to next command, if no more commands, STOP
STOP, STOPDONE: nothing
PLAYFWD: advance to next command, if no commands, STOP,
         if no more commands (and any commands), TURNAROUND
TURNAROUND: PLAYREV
PLAYREV: advance to previous command, if no more commands, STOPDONE

5. @show_current_command is the currently executing command (i.e. the command
   currently animating), this is the highlighted command
5a. @show_current_command is set to the length of the commands array (an
   invalid command index) when in TURNAROUND

6. @next_command is the next command to be run, once it is run increment it. It
   is the length of the total array (invalid index) when no more commands are
   left to be executed in PLAY or PLAYFWD, respectively -1 in PLAYREV

###


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
renderLevel = (level_ctx, prog_ctx, t) ->
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
  #@bot.has_item = true
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

  # obstacles
  show_frame = @frame
  frame_t = 0
  if @animation_mode == levelAnimMode.MOVING
    frame_t = (t - @move_control.start.t) * bot_speed
    show_frame = @frame - 1
  for o in @obstacles
    o.render(ctx, show_frame, frame_t, t)

  # bot
  @bot.render(ctx)

  # commands
  ctx = prog_ctx
  for cmd, i in @commands
    col = i

    cur = i == @show_current_command
    row = 0
    renderCommand(ctx, cmd, (x: col*command_size, y: row*command_size),
      cur and (
        @mode == levelMode.PLAY or
        @mode == levelMode.PLAYFWD), false)

    cur = i == @show_current_command
    row = 1
    renderCommand(ctx, cmd, (x: col*command_size, y: row*command_size),
      cur and @mode == levelMode.PLAYREV, true)

  if @commands.length > 0
    renderCommand(ctx, reverse_cmd,
      (x: @commands.length*command_size, y: .5*command_size),
      @commands.length == @show_current_command and
      @mode == levelMode.TURNAROUND)

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

# obstacle graphics
renderMine = (ctx) ->
    ctx.fillStyle = 'black'
    ctx.strokeStyle = 'white'
    ctx.lineWidth = 1

    ctx.beginPath()
    ctx.moveTo(-cell_size*.35,-cell_size*.35)
    ctx.lineTo(cell_size*.35,cell_size*.35)
    ctx.moveTo(cell_size*.35,-cell_size*.35)
    ctx.lineTo(-cell_size*.35,cell_size*.35)

    ctx.moveTo(0,-cell_size*.4)
    ctx.lineTo(0,cell_size*.4)
    ctx.moveTo(cell_size*.4,0)
    ctx.lineTo(-cell_size*.4,0)
    ctx.stroke()

    ctx.beginPath()
    ctx.arc(0,0, cell_size*.3, 0, Math.PI*2)
    ctx.fill()
    ctx.stroke()

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
    when levelMode.PLAY, levelMode.PLAYFWD
      level.bot.xi += @dir.dx
      level.bot.yi += @dir.dy
      level.bot.dir = @dir.theta
    when levelMode.PLAYREV
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
  if level.mode == levelMode.TURNAROUND || level.mode == levelMode.PLAYREV
    return false
  if level.commands.length >= max_commands
    # TODO: display error
    return false

  level.commands[level.commands.length] = @cmd

  if level.mode == levelMode.STOPDONE
    level.reset()
  if level.mode == levelMode.STOP
    level.mode = levelMode.PLAY
    level.animation_mode = levelAnimMode.READY
    level.last_t = Date.now()/1000

  return true

playButtonAction = (level) ->
  level.resetAndRun()
  level.mode = levelMode.PLAYFWD
  return

undoButtonAction = (level) ->
  if level.commands.length == 0
    return false

  level.commands = level.commands[...-1]

  level.resetAndRun()
  while level.next_command < level.commands.length && level.step()
    true

  level.mode = levelMode.STOP

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

# obstacles
class Static_obstacle
  constructor: (@xi, @yi) ->

  render: (ctx, frame, frame_t, t) ->
    ctx.save()
    ctx.translate((@xi + .5)*cell_size+.5, (@yi + .5)*cell_size+.5)

    renderMine(ctx)
    ctx.restore()
    return

  isHit: (xi, yi, frame) ->
    return xi == @xi and yi == @yi

class Mobile_obstacle
  constructor: (@xi, @yi, @dxi, @dyi) ->

  render: (ctx, frame, frame_t, t) ->
    distx = (frame + frame_t) * @dxi
    disty = (frame + frame_t) * @dyi

    ctx.save()

    ctx.translate((@xi + .5 + distx)*cell_size+.5,
                  (@yi + .5 + disty)*cell_size+.5)

    renderMine(ctx)
    ctx.restore()
    return

  isHit: (xi, yi, frame) ->
    # NOTE: if the obstacle is to move more than one cell per frame in some
    # direction, this check will need to be expanded
    return xi == @xi+frame*@dxi and yi == @yi+frame*@dyi

# level logic

levelMode =
  STOP: 1
  PLAY: 2
  PLAYFWD: 3
  TURNAROUND: 4
  PLAYREV: 5

levelAnimMode =
  READY: 1  # ready to run the next command
  MOVING: 2 # animating movement

resetLevel = ->
  @bot.showxi = @bot.xi = @initial_bot_location.xi
  @bot.showyi = @bot.yi = @initial_bot_location.yi
  @bot.showdir = @bot.dir = @initial_bot_location.dir
  @bot.has_item = false

  @show_current_command = 0
  @next_command = 0
  @frame = 0

  @mode = levelMode.STOP

  @animation_mode = levelAnimMode.READY
  delete @move_control
  @last_t = Date.now()/1000

  return

resetAndRunLevel = ->
  @reset()
  @mode = levelMode.PLAYFWD

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
    step_ok = false

    switch @mode
      when levelMode.PLAY
        if @next_command < @commands.length
          step_ok = true
        else
          @mode = levelMode.STOP

      when levelMode.PLAYFWD
        if @next_command < @commands.length
          step_ok = true
        else if @commands.length > 0
          @mode = levelMode.TURNAROUND
          step_ok = true
        else
          @mode = levelMode.STOP

      when levelMode.TURNAROUND
        @next_command = @commands.length-1
        @mode = levelMode.PLAYREV

      when levelMode.PLAYREV
        if @next_command >= 0
          step_ok = true
        else
          @mode = levelMode.STOPDONE

    @bot.showxi = @bot.xi
    @bot.showyi = @bot.yi
    @bot.showdir = @bot.dir

    if step_ok
      step_command = @next_command

      next_move_control =
        start: (t: t, x: @bot.xi, y: @bot.yi, dir: @bot.dir)
        duration: 1/bot_speed
      if @step()
        @move_control = next_move_control
        @animation_mode = levelAnimMode.MOVING
        @show_current_command = step_command
      else
        # TODO: Need to play a death animation and restart

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
  # bot gets item when leaving its cell
  if @bot.xi == @item_location.xi and @bot.yi == @item_location.yi
    @bot.has_item = true

  if @mode isnt levelMode.TURNAROUND # @next_command is illegal for TURNAROUND
    @commands[@next_command].action(this)

  @frame++

  # check if this move takes us into an obstacle
  for o in @obstacles
    if o.isHit(@bot.xi, @bot.yi, @frame)
      console.log("hit obstacle at frame " + @frame)
      # TODO: error display, take back move (I think that goes elsewhere)
      #return false

  @advanceNextCommand()

  return true

setupLevel = (initial_bot_location, item_location, obstacles) ->
  o =
    initial_bot_location: initial_bot_location
    item_location: item_location
    obstacles: obstacles
    bot: (render: renderBot)
    commands: [ ]
    next_command: 0
    show_current_command: -1
    render: renderLevel
    animate: animateLevel
    step: stepLevelSimulation

    advanceNextCommand: ->
      switch @mode
        when levelMode.PLAY, levelMode.PLAYFWD
          @next_command++
        when levelMode.PLAYREV
          @next_command--
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
level_state = setupLevel(
  (xi:0, yi:5, dir:0), (xi:6, yi:5),
  [new Static_obstacle(1,5),
   new Mobile_obstacle(2,1,0,1)]
  )

stop = false

render = ->
  t = Date.now()/1000

  clear(level_cnv, level_ctx)
  clear(prog_cnv, prog_ctx)

  level_state.animate(t)
  level_state.render(level_ctx, prog_ctx, t)

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

