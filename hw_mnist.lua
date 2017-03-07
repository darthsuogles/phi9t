-- Using a local scope to help protopything in REPL
-- https://www.lua.org/pil/15.4.html
require('./torch_init.lua')
local is_repl = IS_REPL or false
env_pkgs = load_pkg({
      'torch',
      'sys',
      'nn',
      'image',
      'pl',
      'paths',
	  'xlua',
	  'optim',
      'mnist', 
      'io',
      'os',
      'math'
}, is_repl)
-- local math = math
local _collectgarbage = collectgarbage
if (not is_repl) then setfenv(1, env_pkgs) end
-- END of package include

torch.manualSeed(1)
torch.setnumthreads(1)
print('<torch> set nb of threads to ' .. torch.getnumthreads())
torch.setdefaulttensortype('torch.FloatTensor')

classes = {'1','2','3','4','5','6','7','8','9','10'}
geometry = {32, 32}
model = nn.Sequential()

------------------------------------------------------------
-- convolutional network 
------------------------------------------------------------
-- stage 1 : mean suppresion -> filter bank -> squashing -> max pooling
model:add(nn.SpatialConvolutionMM(1, 32, 5, 5))
model:add(nn.Tanh())
model:add(nn.SpatialMaxPooling(3, 3, 3, 3, 1, 1))
-- stage 2 : mean suppresion -> filter bank -> squashing -> max pooling
model:add(nn.SpatialConvolutionMM(32, 64, 5, 5))
model:add(nn.Tanh())
model:add(nn.SpatialMaxPooling(2, 2, 2, 2))
-- stage 3 : standard 2-layer MLP:
model:add(nn.Reshape(64*3*3))
model:add(nn.Linear(64*3*3, 200))
model:add(nn.Tanh())
model:add(nn.Linear(200, #classes))
------------------------------------------------------------
-- retrieve parameters and gradients
parameters, gradParameters = model:getParameters()

----------------------------------------------------------------------
-- loss function: negative log-likelihood
--
model:add(nn.LogSoftMax())
criterion = nn.ClassNLLCriterion()

----------------------------------------------------------------------
-- get/create dataset
--
nbTrainingPatches = 60000
nbTestingPatches = 10000

-- create training set and normalize
trainData = mnist.traindataset()
testData = mnist.testdataset()
print(trainData.size) -- to retrieve the size
print(testData.size) -- to retrieve the size

----------------------------------------------------------------------
-- define training and testing functions
--
-- this matrix records the current confusion across classes
confusion = optim.ConfusionMatrix(classes)

-- log results to files
trainLogger = optim.Logger('mnist_train.log')
testLogger = optim.Logger('mnist_test.log')

batchSize = 300
optimization = 'LBFGS'
coefL1 = 0.0007
coefL2 = 0.0007

-- training function
function train(dataset)
   -- epoch tracker
   epoch = epoch or 1

   -- local vars
   local time = sys.clock()

   -- do one epoch
   print('<trainer> on training set:')
   print("<trainer> online epoch # " .. epoch .. ' [batchSize = ' .. batchSize .. ']')
   for t = 1, dataset.size, batchSize do
      -- create mini batch
      local inputs = torch.Tensor(batchSize, 1, geometry[1], geometry[2])
      local targets = torch.Tensor(batchSize)
      local k = 1
      for i = t, math.min(t + batchSize - 1, dataset.size) do
         -- load new sample
         local input = dataset.data[i]:clone()
         inputs[k] = input:resize(geometry[1], geometry[2])
         targets[k] = dataset.label[i] + 1 
         k = k + 1
      end
      
      -- create closure to evaluate f(X) and df/dX
      local feval = function(x)
         -- just in case:
         _collectgarbage()

         -- get new parameters
         if x ~= parameters then
            parameters:copy(x)
         end

         -- reset gradients
         gradParameters:zero()

         -- evaluate function for complete mini batch
         local outputs = model:forward(inputs)
         local f = criterion:forward(outputs, targets)

         -- estimate df/dW
         local df_do = criterion:backward(outputs, targets)
         model:backward(inputs, df_do)

         -- penalties (L1 and L2):
         local norm, sign = torch.norm, torch.sign

         -- Loss:
         f = f + coefL1 * norm(parameters, 1)
         f = f + coefL2 * norm(parameters, 2)^2 / 2

         -- Gradients:
         gradParameters:add( 
            sign(parameters):mul(coefL1) + parameters:clone():mul(coefL2) )

         -- update confusion
         for i = 1, batchSize do
            confusion:add(outputs[i], targets[i])
         end

         -- return f and df/dX
         return f, gradParameters
      end

      -- optimize on current mini-batch
      if optimization == 'LBFGS' then

         -- Perform LBFGS step:
         lbfgsState = lbfgsState or {
            maxIter = 15,
            lineSearch = optim.lswolfe
         }
         optim.lbfgs(feval, parameters, lbfgsState)
       
         -- disp report:
         print('LBFGS step')
         print(' - progress in batch: ' .. t .. '/' .. dataset.size)
         print(' - nb of iterations: ' .. lbfgsState.nIter)
         print(' - nb of function evalutions: ' .. lbfgsState.funcEval)

      elseif optimization == 'SGD' then

         -- Perform SGD step:
         sgdState = sgdState or {
            learningRate = opt.learningRate,
            momentum = opt.momentum,
            learningRateDecay = 5e-7
         }
         optim.sgd(feval, parameters, sgdState)
      
         -- disp progress
         xlua.progress(t, dataset.size)

      else
         error('unknown optimization method')
      end
   end
   
   -- time taken
   time = sys.clock() - time
   time = time / dataset.size
   print("<trainer> time to learn 1 sample = " .. (time*1000) .. 'ms')

   -- print confusion matrix
   print(confusion)
   trainLogger:add{['% mean class accuracy (train set)'] = confusion.totalValid * 100}
   confusion:zero()

   -- save/log current net
   local filename = 'mnist.net'
   os.execute('mkdir -p ' .. sys.dirname(filename))
   if paths.filep(filename) then
      os.execute('mv ' .. filename .. ' ' .. filename .. '.old')
   end
   print('<trainer> saving network to '..filename)
   -- torch.save(filename, model)

   -- next epoch
   epoch = epoch + 1
end

-- test function
function test(dataset)
   -- local vars
   local time = sys.clock()

   -- test over given dataset
   print('<trainer> on testing Set:')
   for t = 1, dataset.size, batchSize do
      -- disp progress
      xlua.progress(t, dataset.size)

      -- create mini batch
      local inputs = torch.Tensor(batchSize, 1, geometry[1], geometry[2])
      local targets = torch.Tensor(batchSize)
      local k = 1
      for i = t, math.min(t + batchSize - 1, dataset.size) do
         -- load new sample
         local input = dataset.data[i]:clone()
         inputs[k] = input:resize(geometry[1], geometry[2]):double()
         targets[k] = dataset.label[i] + 1
         k = k + 1
      end

      -- test samples
      local preds = model:forward(inputs)

      -- confusion:
      for i = 1, batchSize do
         confusion:add(preds[i], targets[i])
      end
   end

   -- timing
   time = sys.clock() - time
   time = time / dataset.size
   print("<trainer> time to test 1 sample = " .. (time*1000) .. 'ms')

   -- print confusion matrix
   print(confusion)
   testLogger:add{['% mean class accuracy (test set)'] = confusion.totalValid * 100}
   confusion:zero()
end

----------------------------------------------------------------------
-- and train!
--
while true do
   -- train/test
   train(trainData)
   test(testData)

   -- -- plot errors
   -- if opt.plot then
   --    trainLogger:style{['% mean class accuracy (train set)'] = '-'}
   --    testLogger:style{['% mean class accuracy (test set)'] = '-'}
   --    trainLogger:plot()
   --    testLogger:plot()
   -- end
end
