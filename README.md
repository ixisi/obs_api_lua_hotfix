# obs_api_lua_hotfix

FOR OBS API LUA PROGRAMMING

# HOW TO USE
* OPTION 1 

  *DOWNLOAD THE FILE AND COPY AND PASTE IT TO YOUR PROJECT!*
* OPTION 2 **USING SOCKET TO LOAD THE FILE**

   ```lua
   local socket= require("socket.http")
   local code= socket.request("https://github.com/ixisi/obs_api_lua_hotfix/obs_api_hotfix.lua")
   loadstring(code)()
   ```


   
