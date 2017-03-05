
import numpy as np
import torch as th
from torch.autograd import Variable

x = th.Tensor(5, 3)
# x = torch.rand(5, 3)
# x.size()

y = th.rand(5, 3)
x + y
y.add_(x)  # mutating y

a = th.ones(5)
a.numpy()  # bridge to numpy
a.add_(1)
b = th.from_numpy(np.ones(5))

x = Variable(th.ones(2, 2), requires_grad=True)
y = x + 2
y.creator  # basic_ops.AddConstant
z = y * y + 3
t = z.mean()
t.backward()
print(x.grad)
