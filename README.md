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
# form(properties_t, title)
```lua
local my_form= obs.script.form(parent, title)
-- use .add function to add anything to the form e.g(my_form.add.button(...))
my_form.add.button(id, title, ...etc) -- this will add the button to current form (Notice when using .add you don't not need to give a parent)
my_form.get(id) -- will return the property from the form
my_form.free/remove() -- will remove the form itself and everything related to it
my_form.hide() -- will hide the form
my_form.show() -- will show the form
my_form.remove() -- will remove the form

my_form.onexit:hide() -- this will make the form hide itself when the user clicks on 'exit' button
my_form.onexit:remove() -- this will remove the form when the user clicks the 'exit' button
my_form.onexit:idle() -- this will do nothing when the user clicks on the form!
my_form.exit:click(function(property, settings) ...end) -- this function will be executed when the user clicks on the 'exit' button
```
*Notice: when accessing .add this will allow you create objects only for the current form.*

*All the methods for creating objects(property) are supported in the '.add' e.g(.add.list, .add.button, .add.text, ect.)*

# scene:get_source(source_name)
```lua
local my_source= obs.scene:get_source(source_name) -- will return a source from anything that has it
my_source.free() -- will release the source
my_source.data/item -- is the main source itself
my_source.get_source() -- will also return the source (use this if you are working  with sceneitem)
```
*The data that is return by 'get_source()' function is the same fron 'wrap()' function*

*This means it is not an advanced way to manage source but just for quick lookup and confirmation use only.*
# scene:name()
```lua
local current_scene_name= obs.scene:name() -- will return the current active scene's name
print("THIS IS THE CURRENT SCENE: " .. tostring(current_scene_name))
```
# scene:add_to_scene(source)
```lua
obs.scene:add_to_scene(my_new_source) -- adds the source to the current active scene (Notice: this will return true/false)
```
*'add_to_scene' will add a source to the current active scene and will return true if succeeded or false if not.*
# scene:get_scene(scene_name)
```lua
local a_scene= obs.scene:get_scene() -- this will return the current active scene
local sceneitem= a_scene.get(source_name) -- will return a sceneitem fron the scene
sceneitem.data/item -- will return the sceneitem itself
sceneitem.free() -- will release the sceneitem
sceneitem.get_source() -- will return the source of the sceneitem (Notice: No need to release this)
a_scene.group_names() -- returns all the current groups in the scene names
a_scene.add(source) -- will a source to the current scene (Notice: The result return will be a 'wrap' object call .free() to release)
local my_label= a_scene.add_label(unique_id, text) -- will create a new source label in the scene
my_label.text(value) -- set/get text
my_label.font.size(size_t) -- will change the font size
my_label.font.face(font_name) -- change the font name
my_label.size.width(size_t) -- set/get width size
my_label.size.height(size_t) -- set/get height size
my_label.pos.x(value) -- set/get the x position
my_label.pos.y(value) -- set/get the y position
my_label.hide() -- hides the source
my_label.show() -- shows the source
my_label.free() -- release the source
my_label.remove() -- remove the source from the scene
--[[ a_scene.get_label() returns the same object as 'a_scene.add_label' does but in this case it will check if it already exists in the scene and return it]]
local my_other_label= a_scene.get_label(source_name)
my_other_label...
...

```
# MORE DOCUMENTATION COMMING SOON...

