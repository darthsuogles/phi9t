-- Using a local scope to help protopything in REPL
-- https://www.lua.org/pil/15.4.html
require('./torch_init.lua')
local is_repl = IS_REPL or false
salut = load_pkg({
      NN = 'nn',
      IM = 'image', 
      TH = 'torch',	  
	  'xlua',
	  'optim',
      display = 'display', -- https://github.com/szym/display
      'mnist', 
      'io'
}, is_repl)
if (not is_repl) then setfenv(1, salut) end
-- END of package include

local trainset = mnist.traindataset()
local testset = mnist.testdataset()
print(trainset.size) -- to retrieve the size
print(testset.size) -- to retrieve the size

----------------------------------------------------------------------
print '==> define parameters'

-- 10-class problem
noutputs = 10

-- input dimensions
nfeats = 3
width = 32
height = 32
ninputs = nfeats*width*height

-- number of hidden units (for MLP only):
nhiddens = ninputs / 2

-- hidden units, filter sizes (for ConvNet only):
nstates = {64,64,128}
filtsize = 5
poolsize = 2
normkernel = IM.gaussian1D(7)

-- a typical modern convolution network (conv+relu+pool)
nnet = NN.Sequential()

-- stage 1 : filter bank -> squashing -> L2 pooling -> normalization
nnet:add(NN.SpatialConvolutionMM(nfeats, nstates[1], filtsize, filtsize))
nnet:add(NN.ReLU())
nnet:add(NN.SpatialMaxPooling(poolsize,poolsize,poolsize,poolsize))

-- stage 2 : filter bank -> squashing -> L2 pooling -> normalization
nnet:add(NN.SpatialConvolutionMM(nstates[1], nstates[2], filtsize, filtsize))
nnet:add(NN.ReLU())
nnet:add(NN.SpatialMaxPooling(poolsize,poolsize,poolsize,poolsize))

-- stage 3 : standard 2-layer neural network
nnet:add(NN.View(nstates[2]*filtsize*filtsize))
nnet:add(NN.Dropout(0.5))
nnet:add(NN.Linear(nstates[2]*filtsize*filtsize, nstates[3]))
nnet:add(NN.ReLU())
nnet:add(NN.Linear(nstates[3], noutputs))

-- add loss function
nnet:add(NN.LogSoftMax())

print('ConvNet\n' .. nnet:__tostring());

local datum = trainset.data[1]:clone()
nnet:forward(datum:resize(3, 32, 32):double())
