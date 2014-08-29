// Generated by CoffeeScript 1.7.1

/*
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
 */


/*
How does death work?
just reset after animation
 */

(function() {
  var DOWN, LEFT, Mobile_obstacle, RIGHT, Static_obstacle, UP, addCommandButtonAction, animateLevel, arrowButtonRender, arrowCommandRender, bot_points, bot_size, bot_speed, cell_size, clear, clickControlPanel, command_scrim_points, command_size, cont_cnv, cont_ctx, control_bevel, control_panel, control_size, controls_start, down_arrow_cmd, go_down_button, go_left_button, go_right_button, go_up_button, hr3, inner_command_size, inner_control_size, left_arrow_cmd, lerp, levelAnimMode, levelMode, level_cnv, level_ctx, level_state, max_commands, moveCommand, noActionCommand, playButtonAction, play_button, prog_cnv, prog_ctx, render, renderArrow, renderBot, renderButtonScrim, renderCommand, renderControlPanel, renderLevel, renderMine, renderPlayButton, renderUndoButton, resetAndRunLevel, resetLevel, reverseCommandRender, reverseDir, reverse_cmd, right_arrow_cmd, rr3, setupControlPanel, setupLevel, stepLevelSimulation, stop, undoButtonAction, undo_button, up_arrow_cmd;

  level_cnv = document.getElementById('level');

  prog_cnv = document.getElementById('program');

  cont_cnv = document.getElementById('controls');

  level_ctx = level_cnv.getContext('2d');

  prog_ctx = prog_cnv.getContext('2d');

  cont_ctx = cont_cnv.getContext('2d');

  clear = function(cnv, ctx) {
    ctx.fillStyle = 'black';
    return ctx.fillRect(0, 0, cnv.width, cnv.height);
  };

  cell_size = 32;

  renderLevel = function(level_ctx, prog_ctx, t) {
    var cmd, col, ctx, cur, frame_t, i, o, row, show_frame, xi, yi, _i, _j, _k, _l, _len, _len1, _ref, _ref1;
    ctx = level_ctx;
    ctx.save();
    ctx.lineWidth = .5;
    ctx.strokeStyle = 'white';
    for (xi = _i = 1; _i < 10; xi = ++_i) {
      ctx.beginPath();
      ctx.moveTo(xi * 32 + .5, 0);
      ctx.lineTo(xi * 32 + .5, 320);
      ctx.stroke();
    }
    for (yi = _j = 1; _j < 10; yi = ++_j) {
      ctx.beginPath();
      ctx.moveTo(0, yi * 32 + .5);
      ctx.lineTo(320, yi * 32 + .5);
      ctx.stroke();
    }
    ctx.restore();
    ctx.save();
    ctx.lineWidth = 1.5;
    ctx.strokeStyle = 'white';
    ctx.save();
    ctx.translate((this.initial_bot_location.xi + .5) * cell_size, (this.initial_bot_location.yi + .5) * cell_size);
    ctx.beginPath();
    ctx.arc(0, 0, cell_size * .4, 0, Math.PI);
    ctx.stroke();
    ctx.restore();
    if (!this.bot.has_item) {
      ctx.translate((this.item_location.xi + .5) * cell_size, (this.item_location.yi + .5) * cell_size);
    } else {
      ctx.translate((this.bot.showxi + .5) * cell_size, (this.bot.showyi + .5) * cell_size);
    }
    ctx.beginPath();
    ctx.arc(0, 0, cell_size * .4, 0, Math.PI, true);
    ctx.stroke();
    ctx.restore();
    show_frame = this.frame;
    frame_t = 0;
    if (this.animation_mode === levelAnimMode.MOVING) {
      frame_t = (t - this.move_control.start.t) * bot_speed;
      show_frame = this.frame - 1;
    }
    _ref = this.obstacles;
    for (_k = 0, _len = _ref.length; _k < _len; _k++) {
      o = _ref[_k];
      o.render(ctx, show_frame, frame_t, t);
    }
    this.bot.render(ctx, this.animation_mode === levelAnimMode.DYING ? (t - this.move_control.start.t) * bot_speed : 0);
    ctx = prog_ctx;
    _ref1 = this.commands;
    for (i = _l = 0, _len1 = _ref1.length; _l < _len1; i = ++_l) {
      cmd = _ref1[i];
      col = i;
      cur = i === this.show_current_command;
      row = 0;
      renderCommand(ctx, cmd, {
        x: col * command_size,
        y: row * command_size
      }, cur && (this.mode === levelMode.PLAY || this.mode === levelMode.PLAYFWD), false);
      cur = i === this.show_current_command;
      row = 1;
      renderCommand(ctx, cmd, {
        x: col * command_size,
        y: row * command_size
      }, cur && this.mode === levelMode.PLAYREV, true);
    }
    if (this.commands.length > 0) {
      renderCommand(ctx, reverse_cmd, {
        x: this.commands.length * command_size,
        y: .5 * command_size
      }, this.commands.length === this.show_current_command && this.mode === levelMode.TURNAROUND);
    }
  };

  hr3 = Math.sqrt(3) / 2;

  rr3 = 1 / Math.sqrt(3);

  bot_size = cell_size * .75;

  bot_speed = 4;

  bot_points = [
    {
      x: bot_size * rr3,
      y: 0
    }, {
      x: -bot_size * (hr3 - rr3),
      y: -bot_size / 2
    }, {
      x: -bot_size * (hr3 - rr3),
      y: bot_size / 2
    }
  ];

  renderBot = function(ctx, dying) {
    var bp, intensity;
    bp = bot_points;
    ctx.save();
    ctx.translate((this.showxi + .5) * cell_size, (this.showyi + .5) * cell_size);
    ctx.rotate(-this.showdir);
    ctx.beginPath();
    ctx.moveTo(bp[0].x, bp[0].y);
    ctx.lineTo(bp[1].x, bp[1].y);
    ctx.lineTo(bp[2].x, bp[2].y);
    ctx.closePath();
    ctx.lineWidth = 1.5;
    ctx.fillStyle = 'black';
    intensity = Math.floor((1 - dying) * (1 - dying) * 255);
    if (dying === 0) {
      ctx.strokeStyle = 'white';
    } else {
      ctx.strokeStyle = "rgb(" + intensity + "," + intensity + "," + intensity + ")";
    }
    ctx.fill();
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(bot_points[0].x, bot_points[0].y, bot_size / 4, (1 - 1 / 5) * Math.PI, (1 + 1 / 5) * Math.PI);
    ctx.stroke();
    ctx.restore();
  };

  renderMine = function(ctx) {
    ctx.fillStyle = 'black';
    ctx.strokeStyle = 'white';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(-cell_size * .35, -cell_size * .35);
    ctx.lineTo(cell_size * .35, cell_size * .35);
    ctx.moveTo(cell_size * .35, -cell_size * .35);
    ctx.lineTo(-cell_size * .35, cell_size * .35);
    ctx.moveTo(0, -cell_size * .4);
    ctx.lineTo(0, cell_size * .4);
    ctx.moveTo(cell_size * .4, 0);
    ctx.lineTo(-cell_size * .4, 0);
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(0, 0, cell_size * .3, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
  };

  UP = {
    theta: Math.PI / 2,
    dx: 0,
    dy: -1
  };

  LEFT = {
    theta: Math.PI,
    dx: -1,
    dy: 0
  };

  RIGHT = {
    theta: 0,
    dx: 1,
    dy: 0
  };

  DOWN = {
    theta: -Math.PI / 2,
    dx: 0,
    dy: 1
  };

  reverseDir = function(dir) {
    switch (dir) {
      case UP:
        return DOWN;
      case DOWN:
        return UP;
      case LEFT:
        return RIGHT;
      case RIGHT:
        return LEFT;
    }
  };

  renderArrow = function(ctx, dir, size) {
    var ahs, as;
    as = size * .75;
    ahs = size * .2;
    ctx.rotate(-dir);
    ctx.beginPath();
    ctx.moveTo(-as / 2, 0);
    ctx.lineTo(as / 2, 0);
    ctx.lineTo(as / 2 - ahs, ahs);
    ctx.moveTo(as / 2, 0);
    ctx.lineTo(as / 2 - ahs, -ahs);
    ctx.stroke();
  };

  command_size = 32;

  inner_command_size = 29;

  command_scrim_points = (function() {
    var ics;
    ics = inner_command_size;
    return [
      {
        x: -ics / 2,
        y: -ics / 2
      }, {
        x: -ics / 2,
        y: +ics / 2
      }, {
        x: +ics / 2,
        y: +ics / 2
      }, {
        x: +ics / 2,
        y: -ics / 2
      }
    ];
  })();

  renderCommand = function(ctx, what, where, current, rev) {
    var cs, ics, pt, _i, _len;
    if (rev == null) {
      rev = false;
    }
    cs = command_size;
    ics = inner_command_size;
    ctx.save();
    ctx.lineWidth = 1.5;
    ctx.strokeStyle = 'white';
    ctx.translate(where.x + .5 * cs, where.y + .5 * cs);
    ctx.strokeRect(-ics / 2, -ics / 2, ics, ics);
    if (current) {
      ctx.fillStyle = 'white';
      for (_i = 0, _len = command_scrim_points.length; _i < _len; _i++) {
        pt = command_scrim_points[_i];
        ctx.fillRect(pt.x - ics * .1, pt.y - ics * .1, ics * .2, ics * .2);
      }
    }
    what.render(ctx, rev);
    ctx.restore();
  };

  controls_start = {
    x: 10,
    y: 10
  };

  control_size = 66;

  inner_control_size = 60;

  control_bevel = 6;

  renderControlPanel = function(ctx) {
    var b, i, _i, _len, _ref;
    ctx.translate(controls_start.x, controls_start.y);
    _ref = this.buttons;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      b = _ref[i];
      ctx.save();
      ctx.lineWidth = 1.5;
      if (i !== this.selected_button) {
        ctx.strokeStyle = 'white';
        ctx.fillStyle = 'black';
      } else {
        ctx.strokeStyle = 'black';
        ctx.fillStyle = 'white';
      }
      renderButtonScrim(ctx);
      ctx.translate(inner_control_size / 2, inner_control_size / 2);
      b.render(ctx);
      ctx.restore();
      ctx.translate(0, control_size);
    }
  };

  clickControlPanel = function(clickpos) {
    var b, i, x, y, _i, _len, _ref;
    x = controls_start.x;
    y = controls_start.y;
    _ref = this.buttons;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      b = _ref[i];
      if (clickpos.x > x && clickpos.y > y && clickpos.x < x + control_size && clickpos.y < y + control_size) {
        return [b, i];
      }
      y = y + control_size;
    }
    return [null, -1];
  };

  renderButtonScrim = function(ctx) {
    var cb, ics;
    ctx.save();
    ics = inner_control_size;
    cb = control_bevel;
    ctx.beginPath();
    ctx.moveTo(0, cb);
    ctx.lineTo(cb, 0);
    ctx.lineTo(ics - cb, 0);
    ctx.lineTo(ics, cb);
    ctx.lineTo(ics, ics - cb);
    ctx.lineTo(ics - cb, ics);
    ctx.lineTo(cb, ics);
    ctx.lineTo(0, ics - cb);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.restore();
  };

  renderPlayButton = function(ctx) {
    var bp;
    bp = bot_points;
    ctx.beginPath();
    ctx.moveTo(bp[0].x, bp[0].y);
    ctx.lineTo(bp[1].x, bp[1].y);
    ctx.lineTo(bp[2].x, bp[2].y);
    ctx.closePath();
    ctx.stroke();
  };

  renderUndoButton = function(ctx) {
    var ics;
    ics = inner_control_size * .35;
    ctx.beginPath();
    ctx.moveTo(-ics, -ics);
    ctx.lineTo(ics, ics);
    ctx.moveTo(-ics, ics);
    ctx.lineTo(ics, -ics);
    ctx.stroke();
  };

  moveCommand = function(level) {
    var dir;
    switch (level.mode) {
      case levelMode.PLAY:
      case levelMode.PLAYFWD:
        level.bot.xi += this.dir.dx;
        level.bot.yi += this.dir.dy;
        return level.bot.dir = this.dir.theta;
      case levelMode.PLAYREV:
        dir = reverseDir(this.dir);
        level.bot.xi += dir.dx;
        level.bot.yi += dir.dy;
        return level.bot.dir = dir.theta;
    }
  };

  noActionCommand = function(level) {};

  arrowCommandRender = function(ctx, rev) {
    var ics;
    ics = inner_command_size * (rev ? -1 : 1);
    return renderArrow(ctx, this.dir.theta, ics);
  };

  reverseCommandRender = function(ctx) {
    var ics;
    ics = inner_command_size;
    ctx.beginPath();
    ctx.moveTo(-ics * .2, -ics * .3);
    ctx.lineTo(0, -ics * .3);
    ctx.arc(0, 0, ics * .3, -Math.PI / 2, Math.PI / 2, false);
    ctx.lineTo(-ics * .2, ics * .3);
    ctx.lineTo(-ics * .1, ics * .15);
    ctx.moveTo(-ics * .2, ics * .3);
    ctx.lineTo(-ics * .1, ics * .45);
    ctx.stroke();
  };

  up_arrow_cmd = {
    render: arrowCommandRender,
    dir: UP,
    action: moveCommand
  };

  left_arrow_cmd = {
    render: arrowCommandRender,
    dir: LEFT,
    action: moveCommand
  };

  right_arrow_cmd = {
    render: arrowCommandRender,
    dir: RIGHT,
    action: moveCommand
  };

  down_arrow_cmd = {
    render: arrowCommandRender,
    dir: DOWN,
    action: moveCommand
  };

  reverse_cmd = {
    render: reverseCommandRender
  };

  max_commands = 9;

  addCommandButtonAction = function(level) {
    if (level.mode === levelMode.TURNAROUND || level.mode === levelMode.PLAYREV) {
      return false;
    }
    if (level.commands.length >= max_commands) {
      return false;
    }
    level.commands[level.commands.length] = this.cmd;
    if (level.mode === levelMode.STOPDONE) {
      level.reset();
    }
    if (level.mode === levelMode.STOP) {
      level.mode = levelMode.PLAY;
      level.animation_mode = levelAnimMode.READY;
      level.last_t = Date.now() / 1000;
    }
    return true;
  };

  playButtonAction = function(level) {
    level.resetAndRun();
    level.mode = levelMode.PLAYFWD;
  };

  undoButtonAction = function(level) {
    if (level.commands.length === 0) {
      return false;
    }
    level.commands = level.commands.slice(0, -1);
    level.resetAndRun();
    while (level.next_command < level.commands.length) {
      if (!level.step()) {
        level.reset();
        break;
      }
    }
    return level.mode = levelMode.STOP;
  };

  arrowButtonRender = function(ctx) {
    return renderArrow(ctx, this.dir.theta, inner_control_size);
  };

  go_up_button = {
    render: arrowButtonRender,
    dir: UP,
    cmd: up_arrow_cmd,
    action: addCommandButtonAction
  };

  go_left_button = {
    render: arrowButtonRender,
    dir: LEFT,
    cmd: left_arrow_cmd,
    action: addCommandButtonAction
  };

  go_right_button = {
    render: arrowButtonRender,
    dir: RIGHT,
    cmd: right_arrow_cmd,
    action: addCommandButtonAction
  };

  go_down_button = {
    render: arrowButtonRender,
    dir: DOWN,
    cmd: down_arrow_cmd,
    action: addCommandButtonAction
  };

  play_button = {
    render: renderPlayButton,
    action: playButtonAction
  };

  undo_button = {
    render: renderUndoButton,
    action: undoButtonAction
  };

  Static_obstacle = (function() {
    function Static_obstacle(xi, yi) {
      this.xi = xi;
      this.yi = yi;
    }

    Static_obstacle.prototype.render = function(ctx, frame, frame_t, t) {
      ctx.save();
      ctx.translate((this.xi + .5) * cell_size + .5, (this.yi + .5) * cell_size + .5);
      renderMine(ctx);
      ctx.restore();
    };

    Static_obstacle.prototype.isHit = function(xi, yi, frame) {
      return xi === this.xi && yi === this.yi;
    };

    return Static_obstacle;

  })();

  Mobile_obstacle = (function() {
    function Mobile_obstacle(xi, yi, dxi, dyi) {
      this.xi = xi;
      this.yi = yi;
      this.dxi = dxi;
      this.dyi = dyi;
    }

    Mobile_obstacle.prototype.render = function(ctx, frame, frame_t, t) {
      var distx, disty;
      distx = (frame + frame_t) * this.dxi;
      disty = (frame + frame_t) * this.dyi;
      ctx.save();
      ctx.translate((this.xi + .5 + distx) * cell_size + .5, (this.yi + .5 + disty) * cell_size + .5);
      renderMine(ctx);
      ctx.restore();
    };

    Mobile_obstacle.prototype.isHit = function(xi, yi, frame) {
      return xi === this.xi + frame * this.dxi && yi === this.yi + frame * this.dyi;
    };

    return Mobile_obstacle;

  })();

  levelMode = {
    STOP: 1,
    PLAY: 2,
    PLAYFWD: 3,
    TURNAROUND: 4,
    PLAYREV: 5
  };

  levelAnimMode = {
    READY: 1,
    MOVING: 2,
    DYING: 3
  };

  resetLevel = function() {
    this.bot.showxi = this.bot.xi = this.initial_bot_location.xi;
    this.bot.showyi = this.bot.yi = this.initial_bot_location.yi;
    this.bot.showdir = this.bot.dir = this.initial_bot_location.dir;
    this.bot.has_item = false;
    this.show_current_command = 0;
    this.next_command = 0;
    this.frame = 0;
    this.mode = levelMode.STOP;
    this.animation_mode = levelAnimMode.READY;
    delete this.move_control;
    this.last_t = Date.now() / 1000;
  };

  resetAndRunLevel = function() {
    this.reset();
    this.mode = levelMode.PLAYFWD;
  };

  lerp = function(t, x0, x1) {
    if (t < 0) {
      t = 0;
    }
    if (t > 1) {
      t = 1;
    }
    return (x1 - x0) * t + x0;
  };

  animateLevel = function(t) {
    var next_move_control, rel_t, step_command, step_ok;
    if (this.animation_mode === levelAnimMode.READY) {
      step_ok = false;
      switch (this.mode) {
        case levelMode.PLAY:
          if (this.next_command < this.commands.length) {
            step_ok = true;
          } else {
            this.mode = levelMode.STOP;
          }
          break;
        case levelMode.PLAYFWD:
          if (this.next_command < this.commands.length) {
            step_ok = true;
          } else if (this.commands.length > 0) {
            this.mode = levelMode.TURNAROUND;
            step_ok = true;
          } else {
            this.mode = levelMode.STOP;
          }
          break;
        case levelMode.TURNAROUND:
          this.next_command = this.commands.length - 1;
          this.mode = levelMode.PLAYREV;
          break;
        case levelMode.PLAYREV:
          if (this.next_command >= 0) {
            step_ok = true;
          } else {
            this.mode = levelMode.STOPDONE;
          }
      }
      this.bot.showxi = this.bot.xi;
      this.bot.showyi = this.bot.yi;
      this.bot.showdir = this.bot.dir;
      if (step_ok) {
        step_command = this.next_command;
        next_move_control = {
          start: {
            t: t,
            x: this.bot.xi,
            y: this.bot.yi,
            dir: this.bot.dir
          },
          duration: 1 / bot_speed
        };
        if (this.step()) {
          this.move_control = next_move_control;
          this.animation_mode = levelAnimMode.MOVING;
          this.show_current_command = step_command;
        } else {
          this.move_control = next_move_control;
          this.animation_mode = levelAnimMode.DYING;
          this.show_current_command = step_command;
        }
      }
    }
    if (this.animation_mode === levelAnimMode.MOVING || this.animation_mode === levelAnimMode.DYING) {
      rel_t = (t - this.move_control.start.t) / this.move_control.duration;
      if (rel_t >= 1) {
        if (this.animation_mode === levelAnimMode.DYING) {
          this.reset();
        } else {
          this.animation_mode = levelAnimMode.READY;
        }
      } else {
        this.bot.showxi = lerp(rel_t, this.move_control.start.x, this.bot.xi);
        this.bot.showyi = lerp(rel_t, this.move_control.start.y, this.bot.yi);
        this.bot.showdir = this.bot.dir;
      }
    }
    this.last_t = t;
  };

  stepLevelSimulation = function() {
    var o, _i, _len, _ref;
    if (this.bot.xi === this.item_location.xi && this.bot.yi === this.item_location.yi) {
      this.bot.has_item = true;
    }
    if (this.mode !== levelMode.TURNAROUND) {
      this.commands[this.next_command].action(this);
    }
    this.frame++;
    _ref = this.obstacles;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      o = _ref[_i];
      if (o.isHit(this.bot.xi, this.bot.yi, this.frame)) {
        console.log("hit obstacle at frame " + this.frame);
        return false;
      }
    }
    this.advanceNextCommand();
    return true;
  };

  setupLevel = function(initial_bot_location, item_location, obstacles) {
    var o;
    o = {
      initial_bot_location: initial_bot_location,
      item_location: item_location,
      obstacles: obstacles,
      bot: {
        render: renderBot
      },
      commands: [],
      next_command: 0,
      show_current_command: -1,
      render: renderLevel,
      animate: animateLevel,
      step: stepLevelSimulation,
      advanceNextCommand: function() {
        switch (this.mode) {
          case levelMode.PLAY:
          case levelMode.PLAYFWD:
            return this.next_command++;
          case levelMode.PLAYREV:
            return this.next_command--;
        }
      },
      reset: resetLevel,
      resetAndRun: resetAndRunLevel
    };
    o.reset();
    return o;
  };

  setupControlPanel = function() {
    return {
      buttons: [play_button, undo_button, go_up_button, go_down_button, go_left_button, go_right_button],
      selected_button: null,
      render: renderControlPanel,
      click: clickControlPanel
    };
  };

  control_panel = setupControlPanel();

  level_state = setupLevel({
    xi: 0,
    yi: 5,
    dir: 0
  }, {
    xi: 6,
    yi: 5
  }, [new Static_obstacle(1, 5), new Mobile_obstacle(2, 1, 0, 1)]);

  stop = false;

  render = function() {
    var t;
    t = Date.now() / 1000;
    clear(level_cnv, level_ctx);
    clear(prog_cnv, prog_ctx);
    level_state.animate(t);
    level_state.render(level_ctx, prog_ctx, t);
    if (!stop) {
      return requestAnimationFrame(render);
    }
  };

  requestAnimationFrame(render);

  cont_cnv.addEventListener('click', function(ev) {
    var button, index, pos, _ref;
    pos = getCursorPosition(cont_cnv, ev);
    _ref = control_panel.click(pos), button = _ref[0], index = _ref[1];
    if (button) {
      return button.action(level_state);
    }
  });

  clear(cont_cnv, cont_ctx);

  control_panel.render(cont_ctx);

}).call(this);

//# sourceMappingURL=obot.map
