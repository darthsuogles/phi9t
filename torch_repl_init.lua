IS_REPL = true

-- require 'torch_init.lua'
-- local _load_pkg = load_pkg

-- function load_pkg(pkg_list, is_repl)
--    _load_pkg(pkg_list, false)
-- end

-- load_pkg({
--       NN = 'nn', 
--       IM = 'image', 
--       TH = 'torch', 
--       'mnist', 
--       'io'
-- }, is_repl)

-- if (false == is_repl) then
--    print('NOT IN REPL')
--    setmetatable(_P, {__index = pkg_include_tbl})
--    setfenv(1, _P) 
-- end

