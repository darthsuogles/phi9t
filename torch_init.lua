function load_pkg(pkg_list, is_repl) 
   local include_tbl_expr = 'pkg_include_tbl = {'
   local include_expr = ''
   for k, v in pairs(pkg_list) do 
      if ('number' == type(k)) then k = v end      
      local pkg_include_expr = k .. " = require " .. "'" .. v .. "'"
      include_tbl_expr = include_tbl_expr .. pkg_include_expr .. ', '
      if (false == is_repl) then 
         pkg_include_expr = 'local ' .. pkg_include_expr 
      end
      include_expr = include_expr .. pkg_include_expr .. "\n"
   end
   include_tbl_expr = include_tbl_expr .. "print = print}"
   print(include_expr)
   loadstring(include_expr)()
   print(include_tbl_expr)
   loadstring(include_tbl_expr)()

   if (false == is_repl) then
      local _P = {}
      setmetatable(_P, {global = _G})
      print('NOT IN REPL')
      setmetatable(_P, {__index = pkg_include_tbl})
      return _P
   else
      return pkg_include_tbl
   end
end

function reload_pkg(mod, ...)
    package.loaded[mod] = nil
    return require(mod, ...)
end
