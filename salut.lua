-- Using a local scope to help protopything in REPL
-- https://www.lua.org/pil/15.4.html
require('./torch_init.lua')
local is_repl = IS_REPL or false
salut = load_pkg({
      NN = 'nn',
      IM = 'image', 
      TH = 'torch',
      display = 'display', -- https://github.com/szym/display
      'mnist', 
      'io'
}, is_repl)
if (not is_repl) then setfenv(1, salut) end
-- END of package include
img_data = TH.zero(TH.DoubleTensor(256, 256, 3))

nnet = NN.Sequential()
nnet:add( NN.SpatialConvolution(3,16,5,5) )
nnet:add( NN.Tanh )
nnet:add( NN.SpatialMaxPooling(2,2,2,2) )
nnet:add( NN.SpatialContrastiveNormalization(16, IM.gaussian(3)) )

print(nnet)

-- mnist = require 'mnist'
trainset = mnist.traindataset()
testset = mnist.testdataset()
print(trainset.size) -- to retrieve the size
print(testset.size) -- to retrieve the size

lena = IM.lena()
display.image(lena)

display.plot(TH.cat(TH.linspace(0, 10, 10), TH.randn(10), 2))
