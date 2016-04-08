-- local mein_tbl = {1, 2}
-- local mein_func = function() print('salut tout le monde!') end
-- mein_tbl[mein_func] = 'this prints some value'
-- print(mein_tbl[mein_func])

require 'nn'
require 'image'
local TH = require('torch')
--print(TH)

local img_data = TH.zero(TH.DoubleTensor(256, 256, 3))

local nnet = nn.Sequential()
nnet:add( nn.SpatialConvolution(3,16,5,5) )
nnet:add( nn.Tanh )
nnet:add( nn.SpatialMaxPooling(2,2,2,2) )
nnet:add( nn.SpatialContrastiveNormalization(16, image.gaussian(3)) )

print(nnet)

local mnist = require 'mnist'

local trainset = mnist.traindataset()
local testset = mnist.testdataset()
print(trainset.size) -- to retrieve the size
print(testset.size) -- to retrieve the size

