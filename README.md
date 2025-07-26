# obs_api_lua_hotfix

FOR OBS API LUA PROGRAMMING

# HOW TO USE
* OPTION 1

  *DOWNLOAD/COPY THE FILE AND COPY AND PASTE IT TO YOUR PROJECT!*
# DOCUMENTATION 

### create()
```lua
obs.script.create()
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
button.type(button_type) -- set button type
button.url(url_link) -- set button url link
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
check_box.checked(false or true) -- set/get
```
*Creates a bool checked box and returns*

*The value it takes are 'true' or 'false' if the function is called without any value it will return the current value*
### group()
```lua
obs.script.group(properties_t, id, title, parent, enum_type_id)
```
*Creates a group object and returns it*

*enum_type_id accepts (normal, checked) by default the value is set to 'normal'*
```lua
obs.script.group(properties_t, id, title, obs.enum.group.normal)
obs.script.group(properties_t, id, title, obs.enum.group.checked)
```
### list()
```lua
local option_list= obs.script.list(parent, id, title, enum_type_id, enum_format_id)
option_list.str(display_name, id) -- insert string option
option_list.int(display_name, id) -- insert int option (for int type the id should be a number)
option_list.bul(display_name, id) -- insert boolean option (for bool type the id should be true or false)
option_list.dbl(display_name, id) -- insert float option (for float type the id should be a number)
```
*The calling the methods will return the current list back*

*So you could do these like this*
```lua
option_list.str("Option 1", "option1").str("Option 2", "option2") ...
```
*The code above will create two options for the list on the same line!*
```lua
option_list.clear() -- will remove all the options in the list
local cursor= option_list.cursor(index) -- will return an option on current index
cursor.remove() -- will remove the current option
cursor.disable() -- will disable the current option (only for string format types e.g obs.enum.list.default & obs.enum.list.string)
cursor.enable() -- will enable the current option
cursor.title -- The title shown to the user
cursor.id -- The value stored in the option
cursor.ret() -- will return the list itself
```

# MORE DOCUMENTATION COMMING SOON...

