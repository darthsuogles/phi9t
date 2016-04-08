-- require 'strict'
require 'nn'
require 'xlua'    -- xlua provides useful tools, like progress bars
require 'optim'   -- an optimization package, for online and batch methods
require 'image'   -- for image transforms

local TH = require('torch')
local mnist = require('mnist')

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
normkernel = image.gaussian1D(7)

-- a typical modern convolution network (conv+relu+pool)
nnet = nn.Sequential()

-- stage 1 : filter bank -> squashing -> L2 pooling -> normalization
nnet:add(nn.SpatialConvolutionMM(nfeats, nstates[1], filtsize, filtsize))
nnet:add(nn.ReLU())
nnet:add(nn.SpatialMaxPooling(poolsize,poolsize,poolsize,poolsize))

-- stage 2 : filter bank -> squashing -> L2 pooling -> normalization
nnet:add(nn.SpatialConvolutionMM(nstates[1], nstates[2], filtsize, filtsize))
nnet:add(nn.ReLU())
nnet:add(nn.SpatialMaxPooling(poolsize,poolsize,poolsize,poolsize))

-- stage 3 : standard 2-layer neural network
nnet:add(nn.View(nstates[2]*filtsize*filtsize))
nnet:add(nn.Dropout(0.5))
nnet:add(nn.Linear(nstates[2]*filtsize*filtsize, nstates[3]))
nnet:add(nn.ReLU())
nnet:add(nn.Linear(nstates[3], noutputs))

-- add loss function
nnet:add(nn.LogSoftMax())

print('ConvNet\n' .. nnet:__tostring());

local datum = trainset[1]
-- print(datum.x)
nnet:forward(datum.x)
