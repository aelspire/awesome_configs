
--[[

     Licensed under GNU General Public License v2
      * (c) 2013, Jan Xie

--]]

local icons_dir    = require("lain.helpers").icons_dir

local awful        = require("awful")
local beautiful    = require("beautiful")
local naughty      = require("naughty")

local mouse        = mouse
local io           = io
local string       = { len = string.len }
local tonumber     = tonumber

local setmetatable = setmetatable

-- Taskwarrior notification
-- lain.widgets.contrib.task
local task = {}

local task_notification = nil

function task:hide()
    if task_notification ~= nil then
        naughty.destroy(task_notification)
        task_notification = nil
    end
end

function task:show(scr_pos)
    task:hide()

    local f, c_text

    if task.followmouse then
        local scrp = mouse.screen
    else
        local scrp = scr_pos or task.scr_pos
    end

    f = io.popen('task list')
    local line = f:read("*line")
    if line ~= nil then
        c_text = "<span font='"
                 .. task.font .. " "
                 .. task.font_size .. "' "
                 .. "foreground='"
                 .. beautiful.fg_focus .. "'>"
                 .. f:read("*line"):gsub("\n*$", "")
                 .. "\n</span>"
        f:read("*line")
        c_text = c_text .. "<span font='"
                 .. task.font .. " "
                 .. task.font_size .. "'>"
                 .. f:read("*all"):gsub("\n*$", "")
                 .. "</span>"
        f:close()
    else
        c_text = "<span font='"
                 .. task.font .. " "
                 .. task.font_size .. "' "
                 .. "foreground='"
                 .. beautiful.fg_focus .. "'>"
                 .. "No tasks"
                 .. "\n</span>"
    end

    task_notification = naughty.notify({ text = c_text,
                                         icon = task.notify_icon,
                                         position = task.position,
                                         fg = task.fg,
                                         bg = task.bg,
                                         timeout = task.timeout,
                                         screen = scrp
                                     })
end

function task:prompt_add()
  awful.prompt.run({ prompt = "Add task: " },
      mypromptbox[mouse.screen].widget,
      function (...)
          local f = io.popen("task add " .. ...)
          c_text = "\n<span font='"
                   .. task.font .. " "
                   .. task.font_size .. "'>"
                   .. f:read("*all")
                   .. "</span>"
          f:close()

          naughty.notify({
              text     = c_text,
              icon     = task.notify_icon,
              position = task.position,
              fg       = task.fg,
              bg       = task.bg,
              timeout  = task.timeout,
          })
      end,
      nil,
      awful.util.getdir("cache") .. "/history_task_add")
end

function task:prompt_search()
  awful.prompt.run({ prompt = "Search task: " },
      mypromptbox[mouse.screen].widget,
      function (...)
          local f = io.popen("task " .. ...)
          c_text = f:read("*all"):gsub(" \n*$", "")
          f:close()

          if string.len(c_text) == 0
          then
              c_text = "No results found."
          else
              c_text = "<span font='"
                       .. task.font .. " "
                       .. task.font_size .. "'>"
                       .. c_text
                       .. "</span>"
          end

          naughty.notify({
              title    = "[task next " .. ... .. "]",
              text     = c_text,
              icon     = task.notify_icon,
              position = task.position,
              fg       = task.fg,
              bg       = task.bg,
              timeout  = task.timeout,
              screen   = mouse.screen
          })
      end,
      nil,
      awful.util.getdir("cache") .. "/history_task")
end

function task:attach(widget, args)
    local args       = args or {}

    task.font_size   = tonumber(args.font_size) or 12
    task.font        = args.font or beautiful.font:sub(beautiful.font:find(""),
                       beautiful.font:find(" "))
    task.fg          = args.fg or beautiful.fg_normal or "#FFFFFF"
    task.bg          = args.bg or beautiful.bg_normal or "#FFFFFF"
    task.position    = args.position or "top_right"
    task.timeout     = args.timeout or 7
    task.scr_pos     = args.scr_pos or 1
    task.followmouse = args.followmouse or false

    task.notify_icon = icons_dir .. "/taskwarrior/task.png"
    task.notify_icon_small = icons_dir .. "/taskwarrior/tasksmall.png"

    widget:connect_signal("mouse::enter", function () task:show(task.scr_pos) end)
    widget:connect_signal("mouse::leave", function () task:hide() end)
end

return setmetatable(task, { __call = function(_, ...) return create(...) end })
