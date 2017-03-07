-- Using a local scope to help protopything in REPL
-- https://www.lua.org/pil/15.4.html
require('./torch_init.lua')
local is_repl = IS_REPL or false
pkg_import_tbl = load_pkg({
      NN = 'nn',
      THNN = 'nn.THNN',
      IM = 'image', 
      TH = 'torch',
      'paths',
	  'xlua',
	  'optim',
      -- display = 'display', -- https://github.com/szym/display
      'io',
      'math',
      'os'
                          }, is_repl)
local _setmetatable = setmetatable
if (not is_repl) then setfenv(1, pkg_import_tbl) end
-- END of package include

if (not paths.filep("cifar10torchsmall.zip")) then
   os.execute('wget -c https://s3.amazonaws.com/torch7/data/cifar10torchsmall.zip')
   os.execute('unzip cifar10torchsmall.zip')
end

trainset = TH.load('cifar10-train.t7')
testset = TH.load('cifar10-test.t7')
classes = {'airplane', 'automobile', 'bird', 'cat',
           'deer', 'dog', 'frog', 'horse', 'ship', 'truck'}

_setmetatable(trainset, 
              {__index = function(t, i) 
                  return {t.data[i], t.label[i]} 
              end}
);
trainset.data = trainset.data:double() -- convert the data from a ByteTensor to a DoubleTensor.
function trainset:size() return self.data:size(1) end

print(trainset)
print(testset)
print(classes)

-- display.image(trainset[391][1])

-- this picks {all images, 1st channel, all vertical pixels, all horizontal pixels}
redChannel = trainset.data[{ {}, {1}, {}, {} }] 
print(#redChannel)

mean = {} -- store the mean, to normalize the test set in the future
stdv = {} -- store the standard-deviation for the future
for i = 1, 3 do -- over each image channel
   mean[i] = trainset.data[{ {}, {i}, {}, {} }]:mean() -- mean estimation
   print('Channel ' .. i .. ', Mean: ' .. mean[i])
   trainset.data[{ {}, {i}, {}, {}  }]:add(-mean[i]) -- mean subtraction
   
   stdv[i] = trainset.data[{ {}, {i}, {}, {} }]:std() -- std estimation
   print('Channel ' .. i .. ', Standard Deviation: ' .. stdv[i])
   trainset.data[{ {}, {i}, {}, {} }]:div(stdv[i]) -- std scaling
end


net = NN.Sequential()
net:add(NN.SpatialConvolution(3, 6, 5, 5)) -- 3 input image channels, 6 output channels, 5x5 convolution kernel
net:add(NN.ReLU())                       -- non-linearity 
net:add(NN.SpatialMaxPooling(2,2,2,2))     -- A max-pooling operation that looks at 2x2 windows and finds the max.
net:add(NN.SpatialConvolution(6, 16, 5, 5))
net:add(NN.ReLU())                       -- non-linearity 
net:add(NN.SpatialMaxPooling(2,2,2,2))
net:add(NN.View(16*5*5))                    -- reshapes from a 3D tensor of 16x5x5 into 1D tensor of 16*5*5
net:add(NN.Linear(16*5*5, 120))             -- fully connected layer (matrix multiplication between input and weights)
net:add(NN.ReLU())                       -- non-linearity 
net:add(NN.Linear(120, 84))
net:add(NN.ReLU())                       -- non-linearity 
net:add(NN.Linear(84, 10))                   -- 10 is the number of outputs of the network (in this case, 10 digits)
net:add(NN.LogSoftMax())                     -- converts the output to a log-probability. Useful for classification problems

criterion = NN.ClassNLLCriterion()

trainer = NN.StochasticGradient(net, criterion)
trainer.learningRate = 0.001
trainer.maxIteration = 15 -- just do 5 epochs of training.

trainer:train(trainset)
print(classes[testset.label[100]])
-- display.image(testset.data[100])

testset.data = testset.data:double() -- convert to double
for i = 1, 3 do -- over each channel
   testset.data[{ {}, {i}, {}, {} }]:add(-mean[i])
   testset.data[{ {}, {i}, {}, {} }]:div(stdv[i])
end
horse = testset.data[100]
print(horse:mean(), horse:std())
predicted = net:forward(testset.data[100])
print(predicted:exp()) -- exponentiate log-prob 
for i = 1, predicted:size(1) do
   print(classes[i], predicted[i])
end
