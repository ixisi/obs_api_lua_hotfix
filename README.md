# obs_api_lua_hotfix

FOR OBS API LUA PROGRAMMING

# HOW TO USE
* OPTION 1

  *DOWNLOAD/COPY THE FILE AND COPY AND PASTE IT TO YOUR PROJECT!*
# DOCUMENTATION 

### create()
```lua
obs.create()
```
*Creates and returns properties object*

### property_t global default methods
```lua
property_t.enable() -- enables the property object
property_t.disable() -- disables the property object
property_t.hint(text_value) -- set/get a description for the property, and shows it whenever the mouse hover over it
property_t.hide() -- will hide the property object
property_t.show() -- will show the property object
property_t.onchange(function(property, settings) ... end) -- add an event for any changes to the property object
property_t.get() -- will return property object itself
property_t.free() -- will remove the property object
```
### button()
```lua
local button= obs.script.button(properties, id_name, text, onclick)
button.text(text_value) -- set/get text 
button.click(function(property, settings) ... end) -- add an event when user clicks the button
```
*Creates a button object and returns it*
```lua
local text_label= obs.script.text(parent, id, value, enum_type_id)
text_label.text(value) -- set/get text
text_label.error(value) -- set/get error
text_label.warn(value) -- set/get warn
```
*Creates a label object and returns it*

*enum_type_id accepts (error, text, default) by default the value is set to 'default'*
```lua
obs.script.text(..,, obs.enum.text.default) -- create a text label
obs.script.text(..,, obs.enum.text.error) -- create an error label
obs.script.text(..,, obs.enum.text.warn) -- create a warn label
```
### bool()
```lua
local check_box= obs.script.bool(parent, id, label)
check_box.checked(false or true) -- sets the check box to active if value is true and not if value is false
```
# MORE DOCUMENTATION COMMING SOON...

