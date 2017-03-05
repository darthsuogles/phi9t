
local _ = require ("moses")
_.each({1, 2, 3}, print)
_.each({one = 1, two = 2, three = 3}, print)
t = {'a', 'b', 'c'}
_.each(t, function(i, v)
          t[i] = v:rep(2)
          print(t[i])
          end)
