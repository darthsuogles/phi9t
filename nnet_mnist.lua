-- Using a local scope to help protopything in REPL
-- https://www.lua.org/pil/15.4.html
require('./torch_init.lua')
local is_repl = IS_REPL or false
salut = load_pkg({
      NN = 'nn',
      THNN = 'nn.THNN',
      IM = 'image', 
      TH = 'torch',
      'paths',
	  'xlua',
	  'optim',
      display = 'display', -- https://github.com/szym/display
      'mnist', 
      'io',
      'math'
}, is_repl)
-- Add some global variables here
local setmetatable = setmetatable
if (not is_repl) then setfenv(1, salut) end
-- END of package include

model = NN.Sequential();  -- make a multi-layer perceptron
inputs = 2; outputs = 1; HUs = 20; -- parameters
model:add(NN.Linear(inputs, HUs))
model:add(NN.Tanh())
model:add(NN.Linear(HUs, outputs))
criterion = NN.MSECriterion()

batchSize = 128
batchInputs = TH.Tensor(batchSize, inputs)
batchLabels = TH.DoubleTensor(batchSize)

for i = 1, batchSize do
  local input = TH.randn(2)     -- normally distributed example in 2d
  local label = 1
  if input[1] * input[2] > 0 then     -- calculate label for XOR function
    label = -1;
  end
  batchInputs[i]:copy(input)
  batchLabels[i] = label
end
params, gradParams = model:getParameters()
optimState = { learningRate = 0.01 }

for epoch = 1, 50 do
  -- local function we give to optim
  -- it takes current weights as input, and outputs the loss
  -- and the gradient of the loss with respect to the weights
  -- gradParams is calculated implicitly by calling 'backward',
  -- because the model's weight and bias gradient tensors
  -- are simply views onto gradParams
  local function feval(params)
    gradParams:zero()

    local outputs = model:forward(batchInputs)
    local loss = criterion:forward(outputs, batchLabels)
    local dloss_doutput = criterion:backward(outputs, batchLabels)
    model:backward(batchInputs, dloss_doutput)

    return loss,gradParams
  end
  print(epoch)
  optim.sgd(feval, params, optimState)
end

----------------------------------------------------------------------
print '==> define parameters'

-- 10-class problem
noutputs = 10

-- input dimensions
nfeats = 1
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

-- create training set and normalize
trainData = mnist.traindataset()
testData = mnist.testdataset()
print(trainData.size) -- to retrieve the size
print(testData.size) -- to retrieve the size

local datum = { 
   x = trainData.data[10]:double(),
   y = trainData.label[10] }
print(datum.x)
nnet:forward(datum.x)

-- criterion = NN.ClassNLLCriterion()

-- trainer = NN.StochasticGradient(nnet, criterion)
-- trainer.learningRate = 0.001
-- trainer.maxIteration = 15 -- just do 5 epochs of training.

-- trainer:train(trainData.data:double())
-- print(classes[testset.label[100]])
-- display.image(testset.data[100])

-- testset.data = testset.data:double() -- convert to double
-- for i = 1, 3 do -- over each channel
--    testset.data[{ {}, {i}, {}, {} }]:add(-mean[i])
--    testset.data[{ {}, {i}, {}, {} }]:div(stdv[i])
-- end
-- horse = testset.data[100]
-- print(horse:mean(), horse:std())
-- predicted = net:forward(testset.data[100])
-- print(predicted:exp()) -- exponentiate log-prob 
-- for i = 1, predicted:size(1) do
--    print(classes[i], predicted[i])
-- end
