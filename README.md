# OBS API Lua Hotfix

A custom Lua wrapper for the OBS API, designed to simplify scripting and property management within OBS Studio.

---

## Table of Contents

- [How to Use](#how-to-use)
- [API Reference](#api-reference)
  - [create()](#create)
  - [property\_t Default Methods](#property_t-default-methods)
  - [button()](#button)
  - [text()](#text)
  - [bool()](#bool)
  - [group()](#group)
  - [list()](#list)
  - [form()](#form)
  - [scene](#sceneget_sourcesource_name)[:get](#sceneget_sourcesource_name)[\_source](#sceneget_sourcesource_name)[()](#sceneget_sourcesource_name)
  - [scene](#scenename)[:name](#scenename)[()](#scenename)
  - [scene](#sceneadd_to_scenemy_new_source)[:add](#sceneadd_to_scenemy_new_source)[\_to\_scene](#sceneadd_to_scenemy_new_source)[()](#sceneadd_to_scenemy_new_source)
  - [scene](#sceneget_scene)[:get](#sceneget_scene)[\_scene](#sceneget_scene)[()](#sceneget_scene)
  - [utils.scheduler()](#utilsschedulertimeout_value)
  - [utils.wrap()](#utilswrapobject_t-object_type)

---

## How to Use

**Option 1**

Download or copy the file into your Lua OBS project

---

## API Reference

### create()

```lua
obs.script.create()
```

Creates and returns a new `obs_properties_t` object.

---

### property\_t Default Methods

All property objects support the following chainable methods:

```lua
property_t.enable()              -- Enables the property
property_t.disable()             -- Disables the property
property_t.hint(text_value)     -- Adds tooltip text shown on hover
property_t.hide()               -- Hides the property
property_t.show()               -- Shows the property
property_t.onchange(callback)   -- Sets callback for value changes
property_t.get()                -- Returns the property object itself
property_t.free()               -- Frees/removes the property
```

---

### button()

```lua
local btn = obs.script.button(parent, id, label, onclick)
```

Creates and returns a button object.

```lua
btn.text(text_value)       -- Set or get the button label
btn.type(button_type)      -- Set the button type
btn.url(url_link)          -- Set a URL for link buttons
btn.click(callback)        -- Set click callback
```

---

### text()

```lua
local label = obs.script.text(parent, id, value, enum_type)
```

Creates and returns a text label object.

```lua
label.text(value)          -- Set or get label text
label.error(value)         -- Show error styling
label.warn(value)          -- Show warning styling
```

`enum_type` options:

- `obs.enum.text.default`
- `obs.enum.text.error`
- `obs.enum.text.warn`

---

### bool()

```lua
local checkbox = obs.script.bool(parent, id, label)
```

Creates and returns a boolean checkbox.

```lua
checkbox.checked(true|false) -- Set or get checked state
```

---

### group()

```lua
local grp = obs.script.group(properties, id, title, parent, enum_type)
```

Creates and returns a group property.

`enum_type` options:

- `obs.enum.group.normal`
- `obs.enum.group.checked`

---

### list()

```lua
local list = obs.script.list(parent, id, title, enum_type, format_type)
```

Creates and returns a dropdown or list selector.

```lua
list.str(display, id)   -- Add a string option
list.int(display, id)   -- Add an integer option
list.bul(display, id)   -- Add a boolean option
list.dbl(display, id)   -- Add a float option
list.clear()            -- Remove all options

local item = list.cursor(index)
item.remove()           -- Remove this option
item.disable()          -- Disable the option
item.enable()           -- Enable the option
item.title              -- Display text
item.id                 -- Associated value
item.ret()              -- Returns list for chaining
```

Example chaining:

```lua
list.str("One", "1").str("Two", "2")
```

---

### form()

```lua
local form = obs.script.form(parent, title)
```

Creates and returns a form container for grouping UI elements.

```lua
form.add.button(id, label, ...)       -- Add a button
form.add.text(id, value, enum_type)   -- Add a label
form.add.list(...)                    -- Add a dropdown
...
form.get(id)                          -- Retrieve a specific property
form.free() / form.remove()           -- Remove form and its contents
form.hide() / form.show()             -- Toggle form visibility

form.onexit:hide()    -- Hide on exit
form.onexit:remove()  -- Remove on exit
form.onexit:idle()    -- Do nothing on exit
form.exit:click(cb)   -- Callback on exit button click
```

---

### scene\:get\_source(source\_name)

```lua
local source = obs.scene:get_source(name)
```

Gets a source by name from any context.

```lua
source.free()          -- Free the source
source.data/item       -- The wrapped OBS source
source.get_source()    -- Alias for source itself
```

---

### scene\:name()

```lua
local scene_name = obs.scene:name()
print("Current scene: " .. scene_name)
```

---

### scene\:add\_to\_scene(my\_new\_source)

```lua
local result = obs.scene:add_to_scene(source)
```

Adds a source to the current active scene.

- Returns `true` if added successfully, `false` otherwise.

---

### scene\:get\_scene()

```lua
local scene = obs.scene:get_scene()
local item = scene.get(source_name)
```

Returns the current active scene and access to its items.

```lua
item.data/item       -- The actual sceneitem
item.free()          -- Frees the sceneitem
item.get_source()    -- Gets the source (no need to free)

scene.group_names()  -- List group names in scene
scene.add(source)    -- Adds source, returns wrapped item

-- Add and manage labels
local label = scene.add_label(id, text)
label.text(value)            -- Set text
label.font.size(size)        -- Font size
label.font.face(font)        -- Font name
label.size.width(w)          -- Width
label.size.height(h)         -- Height
label.pos.x(x)               -- X position
label.pos.y(y)               -- Y position
label.hide() / show()        -- Toggle visibility
label.remove() / free()      -- Remove or free

-- Retrieve existing label
local label = scene.get_label(name)

-- Groups
local group = scene.add_group(id, refresh)
group.add(item)         -- Add sceneitem to group
```

Scene resolution:

```lua
scene.get_width()
scene.get_height()
```

---

### utils.scheduler(timeout\_ms)

```lua
local task = obs.utils.scheduler(1000) -- Delay: 1000 ms (1 second)
```

Schedules delayed tasks.

```lua
task.after(function() ... end)  -- Run after timeout
task.push(function() ... end)   -- Add to execution queue
task.clear()                    -- Cancel all scheduled
```

---

### utils.wrap(object, type)

```lua
local wrapped = obs.utils.wrap(obj, obs.utils.OBS_SRC_TYPE)
```

Wraps an OBS object for easier handling.

```lua
wrapped.free()       -- Free manually
wrapped.data/item    -- Access underlying object
wrapped.get_source() -- Alias for item
```

Supported types:

- `OBS_SCENEITEM_TYPE`
- `OBS_SRC_TYPE`
- `OBS_OBJ_TYPE`
- `OBS_ARR_TYPE`
- `OBS_SCENE_TYPE`
- `OBS_SCENEITEM_LIST_TYPE`
- `OBS_SRC_LIST_TYPE`
- `OBS_UN_IN_TYPE`

---

### More Coming Soon...

Stay tuned for more features and helper methods!

