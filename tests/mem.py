print 'MemoryTest!'

print('creating soc')
soc = libbench.RV_SOC('bla')
soc.tick(10)
soc.reset()
print('it`s alive!')
