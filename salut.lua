-- Using a local scope to help protopything in REPL
-- https://www.lua.org/pil/15.4.html
-- Set environment variable to include "$PWD/bin"
require('./torch_init.lua')
local is_repl = IS_REPL or false
salut = load_pkg({
      NN = 'nn',
      IM = 'image', 
      TH = 'torch',
      -- display = 'display', -- https://github.com/szym/display
      'io'
}, is_repl)
if (not is_repl) then setfenv(1, salut) end
-- END of package include

-- Tensor class
z = TH.Tensor(4,5,6,2)
-- fout = TH.MemoryFile()
-- fout:writeObject(z)
s = TH.LongStorage(6)
s[1] = 4; s[2] = 5; s[3] = 6; s[4] = 2; s[5] = 7; s[6] = 3;
z6d = torch.Tensor(s); print(z6d:dim())


-- Create a net
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
nstates = {64, 64, 128}
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

print(nnet)

-- Brush the idea of Lua
-- http://tylerneylon.com/a/learn-lua/
t = {k1 = 1, k2 = 2}
for k, v in pairs(t) do
   print('key', k, 'val', v)
end
-- Either t.k1 or t['k1'] is fine, kinda like in R

-- -- mnist = require 'mnist'
-- trainset = mnist.traindataset()
-- testset = mnist.testdataset()
-- print(trainset.size) -- to retrieve the size
-- print(testset.size) -- to retrieve the size

-- -- Some display functions
-- -- lena = IM.lena()
-- -- display.image(lena)
-- -- display.plot(TH.cat(TH.linspace(0, 10, 10), TH.randn(10), 2))

-- -- setmetatable(trainset, 
-- --              {__index = function(t, i) return {t.data[i], t.label[i]} end});
-- -- trainset.data = trainset.data:double() -- convert the data from a ByteTensor to a DoubleTensor.
-- -- function trainset:size() return self.data:size(1) end

-- criterion = NN.ClassNLLCriterion()
-- nnet:add(criterion)

-- trainer = NN.StochasticGradient(nnet, criterion)
-- trainer.learningRate = 0.001
-- trainer.maxIteration = 15 -- just do 5 epochs of training.

-- trainer:train(trainset)
-- -- print(classes[testset.label[100]])
-- -- display.image(testset.data[100])
