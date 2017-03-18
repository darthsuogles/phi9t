-- Xception model
-- a Torch7 implementation of: https://arxiv.org/abs/1610.02357
-- https://keras.io/applications/#xception
-- https://culurciello.github.io/tech/2016/06/04/nets.html
-- E. Culurciello, October 2016

require 'nn'
local nClasses = 1000

function nn.SpatialSeparableConvolution(nInputPlane, nOutputPlane, kW, kH)
   local block = nn.Sequential()
   block:add(nn.SpatialConvolutionMap(nn.tables.oneToOne(nInputPlane), kW,kH, 1,1, 1,1))
   block:add(nn.SpatialConvolution(nInputPlane, nOutputPlane, 1,1, 1,1, 1,1))
   return block
end

function SepConvBypass(nInputPlane, nOutputPlane, kW,kH, maxW,maxH, maxSW,maxSH, flow, first)
   local sum = nn.ConcatTable()
   local main = nn.Sequential()
   local other = nn.Sequential()
   sum:add(main):add(other)

   if flow == 'entry' then
      if not first then main:add(nn.ReLU()) end
      main:add(nn.SpatialSeparableConvolution(nInputPlane, nOutputPlane, kW, kH))
      main:add(nn.ReLU())
      main:add(nn.SpatialSeparableConvolution(nOutputPlane, nOutputPlane, kW, kH))
      main:add(nn.SpatialMaxPooling(maxW, maxH, maxSW, maxSH))
      main:add(nn.Padding(3,2))
      main:add(nn.Padding(4,2))
      other:add(nn.SpatialConvolution(nInputPlane, nOutputPlane, 1,1, 2,2, 1,1))
   elseif flow == 'middle' then
      main:add(nn.ReLU())
      main:add(nn.SpatialSeparableConvolution(nInputPlane, nOutputPlane, kW,kH))
      main:add(nn.ReLU())
      main:add(nn.SpatialSeparableConvolution(nOutputPlane, nOutputPlane, kW,kH))
      main:add(nn.ReLU())
      main:add(nn.SpatialSeparableConvolution(nOutputPlane, nOutputPlane, kW,kH))
      other:add(nn.Identity())
   elseif flow == 'exit'then
      main:add(nn.SpatialSeparableConvolution(nInputPlane, nInputPlane, kW,kH))
      main:add(nn.ReLU())
      main:add(nn.SpatialSeparableConvolution(nInputPlane, nOutputPlane, kW,kH))
      main:add(nn.SpatialMaxPooling(maxW, maxH, maxSW, maxSH))
      main:add(nn.Padding(3,2))
      main:add(nn.Padding(4,2))
      other:add(nn.SpatialConvolution(nInputPlane, nOutputPlane, 1,1, 2,2, 1,1))
   else
      print('Error: flow must be either: entry, middle, exit')
      return 0
   end

   return nn.Sequential():add(sum):add(nn.CAddTable())
end


local model = nn.Sequential()

-- Entry flow:
model:add(nn.SpatialConvolution(3, 32, 3,3, 2,2, 1,1))  -- input: 3x299x299
model:add(nn.ReLU())
model:add(nn.SpatialConvolution(32, 64, 3,3, 2,2, 1,1)) -- output: 64x75x75
model:add(nn.ReLU())

model:add(SepConvBypass(64, 128, 3,3, 3,3, 2,2, 'entry', true))   -- 75 --> 39
model:add(SepConvBypass(128, 256, 3,3, 3,3, 2,2, 'entry', false)) -- 39 --> 21
model:add(SepConvBypass(256, 768, 3,3, 3,3, 2,2, 'entry', false)) -- 21 --> 12

-- Middle flow
for i=1,8 do
   model:add(SepConvBypass(768, 768, 3,3, 3,3, 2,2, 'middle'))    -- 12 --> 12
end

-- Exit flow
model:add(SepConvBypass(768, 1024, 3,3, 3,3, 2,2, 'exit'))        -- 12 --> 7
model:add(nn.SpatialSeparableConvolution(1024, 1536, 3,3))
model:add(nn.ReLU())
model:add(nn.SpatialSeparableConvolution(1536, 2048, 3,3))        -- 7 --> 7
model:add(nn.ReLU())                                          
model:add(nn.SpatialAveragePooling(7,7))                          -- 7 --> 1
model:add(nn.View(2048))
model:add(nn.Linear(2048, nClasses))
model:add(nn.LogSoftMax())


-- test code:
print(model)
local a = torch.Tensor(1,3,299,299) -- input image test
local b = model:forward(a) -- test network
print(b:size())
