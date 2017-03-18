
from itertools import count
import torch
import torch.autograd
import torch.nn.functional as F
from torch.autograd import Variable

class Polynom(object):
    def __init__(self, degree):
        self.degree = degree
        self.W = torch.randn(degree, 1) * 5
        self.b = torch.randn(1) * 5

       
    @classmethod
    def show(cls, 
             W: torch.FloatTensor, 
             b: torch.FloatTensor):
        desc = 'y ='
        W = W.view(-1)
        for i, w in enumerate(W):
            desc += ' {:+.2f} x^{}'.format(w, len(W) - i)
        desc += ' {:+.2f}'.format(b[0])
        return desc


    def __str__(self):
        return Polynom.show(self.W, self.b)


    def get_batch(self, batch_size=32):
        x_rand = torch.randn(batch_size).unsqueeze(1)
        x = torch.cat([
            x_rand ** i for i in range(1, self.degree + 1)
        ], 1)
        y = x.mm(self.W) + self.b[0]  # must use b[0] as a number
        return Variable(x), Variable(y)


# Learning target
poly = Polynom(degree=4)

# The model
nnet = torch.nn.Linear(poly.degree, 1)

# Train it
print('------- TRAINING ---------')
for batch_idx in count(1):
    batch_x, batch_y = poly.get_batch(64)
    nnet.zero_grad()
    output = F.smooth_l1_loss(nnet(batch_x), batch_y)
    output.backward()
    batch_loss = output.data[0]

    # Upgrade model
    for param in nnet.parameters():
        param.data.add_(-0.003 * param.grad.data)

    if 0 == batch_idx % 100:        
        print('batch', batch_idx, 'loss', batch_loss)
    if batch_loss < 1e-3:
        break

print('------- RESULT ---------')
print('==> Learned function: {}'.format(
      Polynom.show(nnet.weight.data, nnet.bias.data)))
print('==>  Actual function: {}'.format(poly))
