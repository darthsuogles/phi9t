''' OpenAI gym
'''
import gym

for env_type in ['Copy-v0', 'SpaceInvaders-v0']: 
    env = gym.make(env_type)
    env.reset()
    env.render()

