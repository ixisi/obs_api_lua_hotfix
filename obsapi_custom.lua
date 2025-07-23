[[
    Author: iixisii
    contact: @iixisii / @XDeviixisiiX
]]

local obs={utils={
OBS_SCENEITEM_TYPE = 1;OBS_SRC_TYPE = 2;OBS_OBJ_TYPE = 3
OBS_ARR_TYPE = 4;OBS_SCENE_TYPE = 5;OBS_SCENEITEM_LIST_TYPE = 6
OBS_SRC_LIST_TYPE = 7;OBS_UN_IN_TYPE = -1
};scene={};client={};mem={};script={}};

-- schedule an event
scheduled_events = {}
function obs.utils.scheduler(timeout)
    -- if type(timeout) ~= "number" or timeout < 0 then
    --     return obs.script_log(obslua.LOG_ERROR, "[Scheduler] invalid timeout value")
    -- end
    local scheduler_callback = nil
    local function interval()
        obslua.timer_remove(interval)
        if type(scheduler_callback) ~= "function" then
            return
        end
        return scheduler_callback(scheduler_callback)
    end
    
    local self = nil; self = {
        after = function(callback)
            if type(callback) == "function" or type(timeout) ~= "number" or timeout < 0 then
                scheduler_callback = callback
            else
                obslua.script_log(obslua.LOG_ERROR, "[Scheduler] invalid callback/timeout " .. type(callback))
                return false
            end
            obslua.timer_add(interval, timeout)
        end;push = function(callback)
            if callback == nil or type(callback) ~= "function" then
                obslua.script_log(obslua.LOG_WARNING, "[Scheduler] invalid callback at {push} " .. type(callback))
                return false
            end
            obslua.timer_add(callback, timeout)
            table.insert(scheduled_events, callback)
            return {
                clear = function()
                    if callback == nil or type(callback) ~= "function" then
                        return nil
                    end
                    return obslua.timer_remove(callback)
                end;
            }
        end; clear = function()
            if scheduler_callback ~= nil then
                obslua.timer_remove(scheduler_callback)
            end
            for _, clb in pairs(scheduled_events) do
                obslua.timer_remove(clb)
            end
            scheduled_events = {}; scheduler_callback = nil
        end
    }
    return self
end

function obs.utils.wrap(object, object_type)
	local self = nil
	self = {
		type = object_type, data = object;item=object;
        get_source=function()
            if self.type == OBS_SRC_TYPE then
                return self.data
            elseif self.type == OBS_SCENEITEM_TYPE then
                return obslua.obs_sceneitem_get_source(self.data)
            else
                return self.data
            end
        end;
		free = function()
			if self.type == OBS_SCENE_TYPE then
				obslua.obs_scene_release(self.data)
			elseif self.type == OBS_SRC_TYPE then
				obslua.obs_source_release(self.data)
			elseif self.type == OBS_ARR_TYPE then
				obslua.obs_data_array_release(self.data)
			elseif self.type == OBS_OBJ_TYPE then
				obslua.obs_data_release(self.data)
			elseif self.type == OBS_SCENEITEM_TYPE then
				obslua.obs_sceneitem_release(self.data)
			elseif self.type == OBS_SCENEITEM_LIST_TYPE then
				obslua.sceneitem_list_release(self.data)
			elseif self.type == OBS_SRC_LIST_TYPE then
				obslua.source_list_release(self.data)
			elseif self.type == OBS_UN_IN_TYPE then
				self.data = nil;self.item=nil
				return
			else
				self.data = nil
			end
		end
	}
	table.insert(error_wrapper, self)
	return self
end

error_freed = 0
error_wrapper = {};function obs.utils.error_wrapper_handler (callback)
	return function(...)
		local args = {...}
		local data = nil
		local caller = ""
		for i, v in ipairs(args) do
			if caller ~= "" then
				caller = caller .. ","
			end
			caller = caller .. "args[" .. tostring(i) .. "]"
		end
		caller = "return function(callback,args) return callback(" .. caller .. ") end";
		local run = loadstring(caller)
		local success, result = pcall(function()
			data = run()(callback, args)
		end)
		if not success then
			error_freed = 0
			for _, iter in pairs(error_wrapper) do
				if iter and type(iter.free) == "function" then
					local s, r = pcall(function()
						iter.free()
					end)
					if s then
						error_freed = error_freed + 1
					end
				end
			end
			obslua.script_log(obslua.LOG_ERROR, "[ErrorWrapper ERROR] => " .. tostring(result))
		end
		return data
	end
end
-- array handle
function obs.mem.ArrayStack(stack, name, ignoreStack)
	if not ignoreStack then 
		if type(stack) ~= "userdata" then
			stack = nil
		elseif stack and (type(name) ~= "string" or name == "")then
			stack = nil
			obslua.script_log(obslua.LOG_ERROR, "FAILED TO LOAD AN [ArrayStack] INVALID NAME GIVEN")
			return nil
		end
	end
	local self = nil
	self = {
		index = 0;get = function(index)
			if type(index) ~= "number" or index < 0 or index > self.size() then
				return nil
			end
			return obs.mem.PairStack(obslua.obs_data_array_item(self.data, index), nil, true)
		end;next = function()
			if type(self.index) ~= "number" or self.index < 0 or self.index > self.size() then
				return nil
			end
			local temp = self.index;self.index = self.index + 1
			return obs.mem.PairStack(obslua.obs_data_array_item(self.data, temp), nil, true)
		end;find= function(key, value)
			for i=0, self.size() - 1 do
				local itm= self.next()
				if itm.get_str(key) == value or itm.get_int(key) == value 
				or itm.get_bul(key) == value or itm.get_dbl(key) == value then
					return itm
				end
				itm.free()
			end
			return nil
		end;
		
		free = function()
			if self.data == nil then
				return false
			end
			obslua.obs_data_array_release(self.data)
			self.data = nil
			return true
		end;insert = obs.utils.error_wrapper_handler(function(value)
			if value == nil or type(value) ~= "userdata" then
				obslua.script_log("FAILED TO INSERT OBJECT INTO [ArrayStack]")
				return false
			end
			obslua.obs_data_array_push_back(self.data, value)
			return self
		end); size = obs.utils.error_wrapper_handler(function()

			if self.data == nil then
				return 0
			end
			return obslua.obs_data_array_count(self.data);
		end); rm= obs.utils.error_wrapper_handler(function(idx)
			if idx < 0 or self.size() <=0 or idx > self.size() then
				obslua.script_log("FAILED TO RM DATA FROM [ArrayStack] (INVALID IDX)")
				return false
			end
			obslua.obs_data_array_erase(self.data, idx)
			return self
		end)
	}
	if not ignoreStack then
		if stack and name then
			self.data = obslua.obs_data_get_array(stack, name)
		else
			self.data = obslua.obs_data_array_create()
		end
	else
		self.data = stack
	end
	table.insert(error_wrapper, self)
	return self
end
-- pair stack used to manage memory stuff :)
function obs.mem.PairStack(stack, name, ignoreStack)
	if not ignoreStack then
		if type(stack) ~= "userdata" then
			stack = nil
		elseif stack and (type(name) ~= "string" or name == "")then
			stack = nil
			obslua.script_log(obslua.LOG_ERROR, "FAILED TO LOAD AN [PairStack] INVALID NAME GIVEN")
			return nil
		end
	end
	local self = nil; self = {
		free = function()
			if self.data == nil then
				return false
			end
			obslua.obs_data_release(self.data)
			self.data = nil
			return true
		end; str = obs.utils.error_wrapper_handler(function(name, value, def)

			if (name == nil or type(name) ~= "string" or name == "") or (self.data == nil or type(self.data) ~= "userdata") or (value == nil or type(value) ~="string") then
				obslua.script_log(obslua.LOG_ERROR,"FAILED TO INSERT STR INTO [PairStack] " .. "FOR [" .. tostring(name) .. "] " .. " OF VALUE [" .. tostring(value) .. "] TYPE: " .. tostring(type(value)))
				return false
			end
            if def then
                obslua.obs_data_set_default_string(self.data, name, value)
            else
                obslua.obs_data_set_string(self.data, name, value)
            end
            return self
		end);int = obs.utils.error_wrapper_handler(function(name, value, def)
			if (name == nil or type(name) ~= "string" or name == "") or (self.data == nil or type(self.data) ~= "userdata") or (value == nil or type(value) ~="number") then
				obslua.script_log(obslua.LOG_ERROR,"FAILED TO INSERT INT INTO [PairStack] " .. "FOR [" .. tostring(name) .. "] " .. " OF VALUE [" .. tostring(value) .. "] TYPE: " .. tostring(type(value)))
				return false
			end
            if def then
                obslua.obs_data_set_default_int(self.data, name, value)
            else
			    obslua.obs_data_set_int(self.data, name, value)
            end
            return self
		end);dbl=obs.utils.error_wrapper_handler(function(name, value, def)
			if (name == nil or type(name) ~= "string" or name == "") or (self.data == nil or type(self.data) ~= "userdata") or (value == nil or type(value) ~="number") then
				obslua.script_log(obslua.LOG_ERROR,"FAILED TO INSERT INT INTO [PairStack] " .. "FOR [" .. tostring(name) .. "] " .. " OF VALUE [" .. tostring(value) .. "] TYPE: " .. tostring(type(value)))
				return nil
			end
            if def then
                obslua.obs_data_set_default_double(self.data, name, value)
            else
			    obslua.obs_data_set_double(self.data, name, value)
            end
            return self
		end);bul = obs.utils.error_wrapper_handler(function(name, value, def)
			if (name == nil or type(name) ~= "string" or name == "") or (self.data == nil or type(self.data) ~= "userdata") or (type(value) == "nil" or type(value) ~="boolean") then
				obslua.script_log(obslua.LOG_ERROR,"FAILED TO INSERT BUL [PairStack] " .. "FOR [" .. tostring(name) .. "] " .. " OF VALUE [" .. tostring(value) .. "] TYPE: " .. tostring(type(value)))
				return nil
			end
            if def then
                obslua.obs_data_set_default_bool(self.data, name, value)
            else
			    obslua.obs_data_set_bool(self.data, name, value)
            end
            return self
		end); arr = obs.utils.error_wrapper_handler(function(name, value, def)
			if (name == nil or type(name) ~= "string" or name == "") or (self.data == nil or type(self.data) ~= "userdata") or (type(value) ~="userdata") then
				
				obslua.script_log(obslua.LOG_ERROR,"FAILED TO INSERT ARR INTO [PairStack] " .. "FOR [" .. tostring(name) .. "] " .. " OF VALUE [" .. tostring(value) .. "] TYPE: " .. tostring(type(value)))
				return nil
			end
            if def then
                obslua.obs_data_set_default_array(self.data, name, value)
            else
			    obslua.obs_data_set_array(self.data, name, value)
            end
            return self
		end); obj = error_wrapper_handler(function(name, value, def)
			if (name == nil or type(name) ~= "string" or name == "") or (type(self.data) ~= "userdata") or (type(value) ~="userdata") then
				obslua.script_log(obslua.LOG_ERROR,"FAILED TO INSERT OBJ INTO [PairStack] " .. "FOR [" .. tostring(name) .. "] " .. " OF VALUE [" .. tostring(value) .. "] TYPE: " .. tostring(type(value)))
				return nil
			end
            if def then
                obslua.obs_data_set_default_obj(self.data, name, value)
            else
			    obslua.obs_data_set_obj(self.data, name, value)
            end
            return self
		end);
		-- getter
		get_str = obs.utils.error_wrapper_handler(function(name, def)
			if (name == nil or type(name) ~= "string" or name == "") or (type(self.data) ~= "userdata")then
				obslua.script_log(obslua.LOG_ERROR,"FAILED TO GET STR FROM [PairStack] " .. "FOR [" .. tostring(name) .. "] " .. " OF VALUE [" .. tostring(value) .. "] TYPE: " .. tostring(type(value)))
				return nil
			end
            if not def then
			    return obslua.obs_data_get_string(self.data, name)
            else
                return obslua.obs_data_get_default_string(self.data, name)
            end
		end);get_int = obs.utils.error_wrapper_handler(function(name, def)
			if (name == nil or type(name) ~= "string" or name == "") or (type(self.data) ~= "userdata")then
				obslua.script_log(obslua.LOG_ERROR,"FAILED TO GET INT FROM [PairStack] " .. "FOR [" .. tostring(name) .. "] " .. " OF VALUE [" .. tostring(value) .. "] TYPE: " .. tostring(type(value)))
				return nil
			end
            if not def then
			    return obslua.obs_data_get_int(self.data, name)
            else
                return obslua.obs_data_get_default_int(self.data, name)
            end
		end);get_dbl = obs.utils.error_wrapper_handler(function(name, def)
			if (name == nil or type(name) ~= "string" or name == "") or (type(self.data) ~= "userdata")then
				obslua.script_log(obslua.LOG_ERROR,"FAILED TO GET DBL FROM [PairStack] " .. "FOR [" .. tostring(name) .. "] " .. " OF VALUE [" .. tostring(value) .. "] TYPE: " .. tostring(type(value)))
				return nil
			end
            if not def then
			    return obslua.obs_data_get_double(self.data, name)
            else
                return obslua.obs_data_get_default_double(self.data, name)
            end
		end);get_obj = obs.utils.error_wrapper_handler(function(name, def)
			if (name == nil or type(name) ~= "string" or name == "") or (type(self.data) ~= "userdata")then
				obslua.script_log(obslua.LOG_ERROR,"FAILED TO GET OBJ FROM [PairStack] " .. "FOR [" .. tostring(name) .. "] " .. " OF VALUE [" .. tostring(value) .. "] TYPE: " .. tostring(type(value)))
				return nil
			end
            if not def then
			    return obs.mem.PairStack(obslua.obs_data_get_obj(self.data, name), nil, true)
            else
                return obs.mem.PairStack(obslua.obs_data_get_default_obj(self.data, name), nil, true)
            end
		end);get_arr = obs.utils.error_wrapper_handler(function(name, def)
			if (name == nil or type(name) ~= "string" or name == "") or (type(self.data) ~= "userdata")then
				obslua.script_log(obslua.LOG_ERROR,"FAILED TO GET ARR FROM [PairStack] " .. "FOR [" .. tostring(name) .. "] " .. " OF VALUE [" .. tostring(value) .. "] TYPE: " .. tostring(type(value)))
				return nil
			end
            if not def then
			    return obs.mem.ArrayStack(obslua.obs_data_get_array(self.data, name), nil, true)
            else
                return obs.mem.ArrayStack(obslua.obs_data_get_default_array(self.data, name), nil, true)
            end
		end);get_bul = obs.utils.error_wrapper_handler(function(name, def)
			if (name == nil or type(name) ~= "string" or name == "") or (type(self.data) ~= "userdata") then
				obslua.script_log(obslua.LOG_ERROR,"FAILED TO GET BUL FROM [PairStack] " .. "FOR [" .. tostring(name) .. "] " .. " OF VALUE [" .. tostring(value) .. "] TYPE: " .. tostring(type(value)))
				return nil
			end
            if not def then
			    return obslua.obs_data_get_bool(self.data, name)
            else
                return obslua.obs_data_get_default_bool(self.data, name)
            end
		end); del= obs.utils.error_wrapper_handler(function(name)
			obslua.obs_data_erase(self.data, name)
			return true
		end)
	}
	if not ignoreStack then
		if stack and name then
			self.data = obslua.obs_data_get_obj(stack, name)
		else
			self.data = obslua.obs_data_create()
		end
	else
		self.data = stack
	end
	table.insert(error_wrapper, self)
	return self
end


--[[ OBS API CUSTOM ]]
function obs.scene:get_source(source_name)
	if not source_name or not type(source_name) == "string" then
		return nil
	end
	local source = obslua.obs_get_source_by_name(source_name)
	if not source then
		return nil
	end
	return obs.utils.wrap(source, obs.utils.OBS_SRC_TYPE)
end
function obs.scene:get_scene(scene_name)
	local scene;local source_scene;
	if not scene_name or not type(scene_name) == "string" then
		source_scene=obslua.obs_frontend_get_current_scene()
		if not source_scene then
			return nil
		end
		scene= obslua.obs_scene_from_source(source_scene)
	else
		source_scene= obslua.obs_get_source_by_name(scene_name)
		if not source_scene then
			return nil
		end
		scene=obslua.obs_scene_from_source(source_scene)
	end
	local obj_scene_t;obj_scene_t= {
		get_all_groups_names=function()
			local scene_items_list = obs.utils.wrap(
				obslua.obs_scene_enum_items(scene),
				obs.utils.OBS_SCENEITEM_LIST_TYPE
			)
			if scene_items_list == nil or scene_items_list.data == nil then
				return nil
			end
			local list={}
			for _, item in ipairs(scene_items_list.data) do
				local source = obslua.obs_sceneitem_get_source(item)
				if source ~= nil then
					local sourceName = obslua.obs_source_get_name(source)
					if obslua.obs_sceneitem_is_group(item) then
						table.insert(list, sourceName)
					end
				end
			end
			scene_items_list.free()
			return list
		end;
		get= function(source_name)
			local source = obs.scene:get_source(source_name)

			if source == nil or source.data == nil then return nil end
			local scene_item = obs.utils.wrap(
				obslua.obs_scene_sceneitem_from_source(scene, source.data),
				obs.utils.OBS_SCENEITEM_TYPE
			)
			-- check in groups if the current item doesn't exist;
			if not scene_item or scene_item.data == nil then
				scene_item=nil
				for _, gN in ipairs(obj_scene_t.get_all_groups_names()) do
					local groupSource =	obslua.obs_get_source_by_name(gN)
					if groupSource then
						local groupItem = obslua.obs_scene_sceneitem_from_source(scene, groupSource)
						obslua.obs_source_release(groupSource)
						if groupItem then -- iterate through the items in the group and check for (item_name);
							local hasItem = false
							local __ls = obslua.obs_sceneitem_group_enum_items(groupItem)
							if __ls ~= nil then
								for _, it in ipairs(__ls) do
									local s = obslua.obs_sceneitem_get_source(it)
									if s ~= nil then
										local sN = obslua.obs_source_get_name(s)
										if sN == item_name then
											obslua.obs_sceneitem_addref(it)
											scene_item = it
											hasItem = true; break
										end
									end
								end
								obslua.sceneitem_list_release(__ls)
							end
							obslua.obs_sceneitem_release(groupItem)
							if hasItem then
								break
							end
						end
						
					end
				end
				if scene_item then
					scene_item = obs.utils.wrap(scene_item, obs.utils.OBS_SCENEITEM_TYPE)
				else
					source.free()
					return nil
				end
			end
			source.free()
			local obj_source_t;obj_source_t={
				free=scene_item.free;
				item=scene_item.data;
				data=scene_item.data;
				get_source=function()
                    return obslua.obs_sceneitem_get_source(scene_item.data)
                end
				
			}
			return obj_source_t
		end;add=function(source)
			if not source then return false end
			local sceneitem= obslua.obs_scene_add(scene, source)
			if sceneitem == nil then return nil end
			obslua.obs_sceneitem_addref(sceneitem)
			return obs.utils.wrap(sceneitem, obs.utils.OBS_SCENEITEM_TYPE)
		end;get_label=function(name, source)
			if (source == nil or source.data == nil) and name ~= nil and type(name) == "string" and name ~= "" then
				source= obj_scene_t.get(name)
			end
			if not source or not source.data then
				return nil 
			end
			local obj_label_t;obj_label_t={
				remove= function()
					if obj_label_t.data == nil then return true end
					obslua.obs_sceneitem_remove(obj_label_t.data)
					source.free(); obj_label_t.data=nil;obj_label_t.item=nil
					return true
				end;
				hide= function()
					return obslua.obs_sceneitem_set_visible(obj_label_t.data, false)
				end;show = function()
					return obslua.obs_sceneitem_set_visible(obj_label_t.data, true)
				end;
				font= {
					size= function(font_size)
						local src= obs.mem.PairStack(
							obslua.obs_source_get_settings(source.get_source()),
							nil,true
						)
						if not src or not src.data then
							src= obs.mem.PairStack()
						end
						local font= src.get_obj("font")
						if not font or not font.data then
							font= obs.mem.PairStack()
							--font.str("face","Arial")
						end
						if font_size == nil or not type(font_size) == "number" or font_size <= 0 then
							font_size=font.get_int("size")
							font.free();src.free();
							return font_size
						else
							font.int("size", font_size)
						end
						font.free();
						obslua.obs_source_update(source.get_source(), src.data)
						src.free()
						return true
					end;face= function(face_name)
					end
				};text=function(txt)
					local src= obs.mem.PairStack(
						obslua.obs_source_get_settings(source.get_source()),
						nil,true
					)
					if not src or not src.data then
						src= obs.mem.PairStack()
					end
					local res=true
					if txt == nil or txt == "" or type(txt) ~= "string" then
						res=src.get_str("text")
						if not res == nil then
							res= ""
						end
					else
						src.str("text", txt)
					end
					obslua.obs_source_update(source.get_source(), src.data)
					src.free()
					return res
				end;free=function()
					source.free()
					obj_label_t=nil
					return true
				end;data=source.data;item=source.data;size={
					width= function(w)

						--local default_transform= obslua.obs_transform_info()
						--local default_source_info=obslua.obs_source_info()
						--obslua.obs_source_get_info(source.get_source(), default_source_info)
						--obslua.obs_sceneitem_get_info(source.data, default_transform)
						local default_width= obslua.obs_source_get_width(source.get_source())
						--local default_scale_x= default_transform.scale.x;

						if w == nil then return default_width end
						return w
					end;
					height= function(h)
						local default_height= obslua.obs_source_get_height(source.get_source())
						if h == nil then return default_height end
						return h
					end;
				};pos = {
					x=function(val)
						local default_transform= obslua.obs_transform_info()
						obslua.obs_sceneitem_get_info(source.data, default_transform)
						if val == nil then return default_transform.pos.x end
						default_transform.pos.x= val
						obslua.obs_sceneitem_set_info(source.data, default_transform)
						return true
					end;
					y=function(val)
						local default_transform= obslua.obs_transform_info()
						obslua.obs_sceneitem_get_info(source.data, default_transform)
						if val == nil then return default_transform.pos.y end
						default_transform.pos.y= val
						obslua.obs_sceneitem_set_info(source.data, default_transform)
						return true
					end;
				}
			}
			return obj_label_t
		end;
		add_label= function(name, text)
			local src= obs.mem.PairStack()
			if not text then
				text= "Text - Label"
			end
			src.str("text", text)
			local source_label=obslua.obs_source_create("text_gdiplus", name, src.data, nil)
			src.free()
			local obj= obj_scene_t.get_label(
				nil, obj_scene_t.add(source_label)
			)
			if not obj or not obj.data then 
				if source_label then obslua.obs_source_release(source_label) end
				return nil
			end
			-- re-write the release function
            -- [[SEEM LIKE THIS LEADS TO CRUSHES?]]
			local free_func= obj.free;
			obj.free= function()
				obslua.obs_source_release(source_label)
				return free_func()
			end
			return obj
		end;add_group= function(name, refresh)
			if refresh == nil then
				refresh=true
			end
			local obj=obj_scene_t.get_group(nil, obslua.obs_scene_add_group2(scene, name, refresh))
			if not obj or obj.data == nil then return nil end
			-- overwrite the free function to prevent crush/bugs
			obj.free=function() end
			return obj
		end;get_group= function(name, gp)
			local obj;if not gp and name ~= nil then
				obj= obs.utils.wrap(obslua.obs_scene_get_group(scene, name), obs.utils.OBS_SCENEITEM_TYPE)
			elseif gp ~= nil then
				obj= obs.utils.wrap(gp, obs.utils.OBS_SCENEITEM_TYPE)
			else
				return nil
			end
			obj["add"]= function(sceneitem)
				if not sceneitem then
					return false
				end
				obslua.obs_sceneitem_group_add_item(obj.data, sceneitem)
				return true
			end
			obj["release"]= function()
				return obj.free()
			end;obj["item"]= obj.data
			return obj
		end;free= function()
			obslua.obs_source_release(source_scene)
			scene=nil
		end;release= function()
			return obj_scene_t.free()
		end;get_width= function()
			return obslua.obs_source_get_width(source_scene)
		end;get_height = function()
			return obslua.obs_source_get_height(source_scene)
		end
	};
	return obj_scene_t
end
function obs.scene:get_current_scene_name()
	source_scene=obslua.obs_frontend_get_current_scene()
	if not source_scene then
		return nil
	end
	local source_name= obslua.obs_source_get_name(source_scene)
	obslua.obs_source_release(source_scene)
	return source_name
end
function obs.scene:add_to_scene(source)
	if not source then
		return false
	end
	local current_source_scene= obslua.obs_frontend_get_current_scene()
	if not current_source_scene then
		return false
	end
	local current_scene= obslua.obs_scene_from_source(current_source_scene)
	if not current_scene then
		obslua.obs_source_release(current_source_scene)
		return false
	end
	obslua.obs_scene_add(current_scene, source)
	obslua.obs_source_release(current_source_scene)
	return true
end
function obs.script.create()
    return obslua.obs_properties_create()
end
function obs.script.list(p, name, label, type, format)
    return obs.utils.obs_api_properties_patch(obslua.obs_properties_add_list(p, name, label, type, format))
end
function obs.script.button(p, name, label, callback)
    if type(callback)~="function" then callback=function() end end
    return obs.utils.obs_api_properties_patch(obslua.obs_properties_add_button(p, name, label, callback))
end
function obs.script.text(p, name, label, enum_type)
    if(enum_type == nil) then
        enum_type= obslua.OBS_TEXT_INFO;
    end
    return obs.utils.obs_api_properties_patch(obslua.obs_properties_add_text(p, name, label, enum_type))
end 
function obs.script.group(p, name, desc, enum_type, op)
	return obs.utils.obs_api_properties_patch(obslua.obs_properties_add_group(p, name, desc, enum_type, op))
end
function obs.script.bool(p, name, desc)
	return obs.utils.obs_api_properties_patch(obslua.obs_properties_add_bool(p, name, desc))
end
function obs.script.get(pp, name)
	return obs.utils.obs_api_properties_patch(obslua.obs_properties_get(pp, name))
end

-- [[ API UTILS ]]
function obs.utils.obs_api_properties_patch(pp, cb)
	local pp_unique_name= obslua.obs_property_name(pp)
	local item=nil;local objText;local objGlobal={
		cb=cb;disabled=function()
			obslua.obs_property_set_disabled(pp, true)
			return nil
		end;enabled=function()
			obslua.obs_property_set_disabled(pp, false)
			return nil
		end;onchange=function(callback)
			obslua.obs_property_set_modified_callback(pp, function(p, pp, settings)
				return callback(p, pp, settings)
			end);
			return nil
		end;hide= function()
			obslua.obs_property_set_visible(pp, false)
		end;show = function()
			obslua.obs_property_set_visible(pp, true)
			return nil
		end;get= function()
			return pp
		end;hint= function(txt)
			item=obslua.obs_property_set_long_description(pp, txt)
			return nil
		end;free= function(p)
			obslua.obs_properties_remove_by_name(p, pp_unique_name)
			return true
		end;
	};objText={
		error=function(txt)
			obslua.obs_property_text_set_info_type(pp, obslua.OBS_TEXT_INFO_ERROR)
			obslua.obs_property_set_description(pp, txt)
			return objText
		end;
		text=function(txt)
			obslua.obs_property_text_set_info_type(pp, obslua.OBS_TEXT_INFO)
			obslua.obs_property_set_description(pp, txt)
			return objText
		end;warn=function(txt)
			obslua.obs_property_text_set_info_type(pp, obslua.OBS_TEXT_INFO_WARNING)
			obslua.obs_property_set_description(pp, txt)
			return objText
		end;
	};local objList;objList={
		item=nil;clear= function()
			objList.item=obslua.obs_property_list_clear(pp)
			return objList
		end;add_str= function(id, title)
			objList.item=obslua.obs_property_list_add_string(pp, title, id)
			return objList
		end;add_int= function(id, title) 
			objList.item=obslua.obs_property_list_add_int(pp, title, id)
			return objList
		end;cursor = function(index)
			
			local nn_obj=nil;nn_obj={
				disabled= function()
					obslua.obs_property_list_item_disable(pp, objList.item, true)
					return nn_obj
				end; enabled= function()
					obslua.obs_property_list_item_disable(pp, objList.item, false)
					return nn_obj
				end;
				ret=function()
					return objList
				end
			}
			return nn_obj;
		end
	};local objButton;objButton={
		item=nil;click= function(callback)
			if type(callback) ~= "function" then
				obslua.script_log(obslua.LOG_ERROR, "[button.click] invalid callback type " .. type(callback))
				return objButton
			end
			objButton.item=obslua.obs_property_button_set_callback(pp, function(p, pp, settings)
				return callback(p, pp, settings)
			end)
			return objButton
		end;
	};local objGroup;objGroup={};
	local property_type= obslua.obs_property_get_type(pp)
	if property_type == obslua.OBS_PROPERTY_GROUP then
		table.append(objGroup, objGlobal)
		return objGroup;
	elseif property_type == obslua.OBS_PROPERTY_LIST then
		table.append(objList, objGlobal)
		return objList;
	elseif property_type == obslua.OBS_PROPERTY_BUTTON then
		table.append(objButton, objGlobal)
		return objButton;
	elseif property_type == obslua.OBS_PROPERTY_TEXT then
		table.append(objText, objGlobal)
		return objText;
	else
		return objGlobal;
	end
end
