# encoding: utf8


""" Definition of the world of the firefighter robot

Five sensors:
- Light
- Temp.
- Proxim.
- Cell
- Battery

On run, it writes sensors into pipe 'tube'.

Then, input is read from pipe 'tube'

Inputs must be a list (with brackets) of values in
fwd | turnL | turnR | put-off | end
Trailing dot is accepted
e.g. '[turnR,fwd,turnL,fwd,put-off].'
if end is received, when it is processed the script ends.

output is written back again to 'tube'

In order to use it you can echo commands into tube and, then, read the output

$ cat tube
$ echo '[fwd]'>tube
$ cat tube
$ echo '[turnR,fwd].'>tube
...



""" 

import numpy as np
import sys

# Some stats
cycles_alive = 0
recharges = 0
fires_done = 0
cycles_without_fire = 0

# Size of the world
size = 10

domain = {'obstacles' : [[2,3],[7,8],[6,3]] ,
          'fires'      : [[8,0]] ,
          'base'      : (5,6)}

if len(sys.argv) > 1:
    max_fires = sys.argv[1]
else:
    max_fires = np.inf

location = np.array(domain['base'])
direction = np.array([-1,0])
state = 'alive'

cycles_from_last_recharge = 0

# test conditions (clauses)

# alternative (different) condition: "if np.count_nonzero( abs(location-base) == 1 ) == 1" means in von-neumann b'dry
def is_black(cell):
    return any( cell-np.array(domain['base']) == 0 )

def is_wall(cell):
    return any(cell < 0 ) or any(cell >= size)

def is_obstacle(cell):
    return list(cell) in domain['obstacles']

def is_base(cell):
    return all(cell==np.array(domain['base']))

def is_fire(cell):
    return any([all(cell==np.array(f)) for f in domain['fires']])

def fires():
    return domain['fires']

def base():
    return np.array(domain['base'])
    
def front():
    return location+direction
    

# SENSORS

def get_cell_sensor():
    # cell sensor
    if is_base(location):
        return 'base'
    if is_black(location):
        return 'black'
    return 'normal'
    
def get_temp_sensor():
    # temperature sensor
    if is_base(location):
        return 'equal'
    if is_base(front()):
        return 'up' 
    
    if fires() != [] and any( [ (np.array(f)-location).dot(direction) >0 for f in fires() ] ):
        return 'up'
    if fires() != [] and any( [ (np.array(f)-location).dot(direction) <0 for f in fires() ] ):
         return 'down'
    return 'equal'
    
def get_prox_sensor():
    # proximity sensor
    # check if out or range or front is an obstacle
    return 'true' if is_obstacle(front()) or is_wall(front()) else 'false'

def get_light_sensor():
    # light sensor
    if is_black(front()) or is_wall(front()):
        return 'dark' 
    if is_fire(front()):
        return 'bright' 
    return 'normal'

def get_batt_sensor():
    # battery sensor
    if 0 <= cycles_from_last_recharge <= 10:
        return 'high'
    if 10 < cycles_from_last_recharge <= 30:
        return 'medium'
    if 30 < cycles_from_last_recharge <= 50:
        return 'low'
    if cycles_alive > 1000:
        print("\n\n\n   I've seen things you people wouldn't believe. Attack ships on fire off the shoulder of Orion. I watched C-beams glitter in the dark near the Tannhauser Gate. All those moments will be lost in time, like tears in rain. Time to die.\n\n\n")
    else:
        print('  You have made me die of starvation!!! Why did not you send me to the base???')
    return 'dead'


def get_sensors():
    sensor_get = {'cell':get_cell_sensor,
                'temp':get_temp_sensor,
                'prox':get_prox_sensor,
                'light':get_light_sensor,
                'batt':get_batt_sensor}
    return {s:sensor_get[s]() for s in ['cell','temp','prox','light','batt']}
#



def process(actions):
    global state,cycles_from_last_recharge
    global cycles,cycles_alive,cycles_without_fire,recharges,fires_done
    if state is 'dead':
        return 'dead'
    
    
    global location,direction
    actions_list = actions.rstrip('. \n')
    actions_list = actions_list[1:-1]
    actions_list = actions_list.split(',')

    print('process '+str(actions_list))

    for ac in actions_list:
        if ac == 'end':
            return 'end'
        
        cycles_from_last_recharge += 1
        cycles_alive += 1
        if fires() == []:
            cycles_without_fire += 1

        if ac == 'turnL':
            direction = np.array( (-direction[1], direction[0] ) )
            
        if ac == 'turnR':
            direction = np.array( ( direction[1],-direction[0] ) )

        if ac == 'fwd':
            front = location+direction
            if is_wall(front) or is_obstacle(front):
                continue

            location = front

            if is_fire(location):
                state = 'dead'
                print('You have made me jump over the fire!. I am dead.')
                return 'dead'

            if is_base(location):
                recharges += 1
                cycles_from_last_recharge = 0

        if ac == 'put-out':
            cycles_from_last_recharge += 4
            cycles_alive += 4
            front = location+direction
            if is_fire(front):
                fires_done += 1
                print(front)
                print(domain['fires'])
                domain['fires'].remove(list(front))

    return 'done'

def print_sepline(num):
	sys.stdout.write('   ')
	for c in range(0,size):
		sys.stdout.write('+---')
	sys.stdout.write('+\n')

def print_world(world):
	sys.stdout.write('   ')
	for c in range(0,size):
		sys.stdout.write('| '+str(c)+' ')
	sys.stdout.write('|\n')
	for r in range(0,size):
		print_sepline(size)
		sys.stdout.write(' '+str(size-r-1)+' ')
		for c in range(0,size):
			sys.stdout.write('| '+world[r][c]+' ')
		sys.stdout.write('|\n')
	print_sepline(size)
	sys.stdout.flush()

def looking_to(direction):
	if (np.array_equal(direction,[0,-1])):
		return('down')
	if (np.array_equal(direction,[0,1])):
		return('up')
	if (np.array_equal(direction,[1,0])):
		return('right')
	if (np.array_equal(direction,[-1,0])):
		return('left')
	return(str(direction)+' (but that seems to be a strange direction...)')

def print_robot_loc_or(location,direction):
	print(' ')
	print('  Robot is now at ('+str(location[1])+','+str(location[0])+') and looking '+looking_to(direction))

def print_obstacles_loc(places):
	sys.stdout.write('  Obstacles are placed at ')
	for i in range(0,len(places)):
		sys.stdout.write('('+str(places[i][1])+','+str(places[i][0])+') ')
	sys.stdout.write('\n')

def print_charge_info():
	print('  We should recharge in no more than '+str(50-cycles_from_last_recharge)+' cycles.')

def print_logbook():
    print('   Logbook of a firefighter robot:')
    print('      Cycle '+str(cycles_alive)+' and still alive. So far, '+str(fires_done)+' fires have been put out.')
    print('      During this time, I managed to keep the world free of fire and')
    print('      devastation (well, only of fire) for ' +str(cycles_without_fire)+' cycles,')
    print('      which is a '+str(int((100.0*cycles_without_fire)/cycles_alive))+'% of the time.')
    if recharges > 0:
        print('      Thanks to your wise gidance, I managed to recharge '+str(recharges)+' times.')
        print('      I\'m grateful to you for that.')

def plot_world(domain,location,direction):
    robot_char = {(1,0): '>' , (-1,0): '<' , (0,1): '^' , (0,-1): 'v' }
    
    world = np.ndarray( shape=(size,size),dtype=object)
    
    world.fill(' ')
    
    # BASE and its lines
    b = domain['base']
    for i in range(0,size):
        world[-b[1]-1][i]='-'
    for i in range(0,size):
        world[i][b[0]]='|'
    world[-b[1]-1][b[0]] = 'B'

    # FIRE
    for f in fires():
        world[-f[1]-1][f[0]] = 'F'

    # OBSTACLES
    for o in domain['obstacles']:
        world[-o[1]-1][o[0]] = 'O'

    # ROBOT (the last thing to fill, since it must be visible whatever it is crossing over)
    world[-location[1]-1][location[0]] = robot_char[tuple(direction)]

    if cycles_alive > 0:
        print_logbook()
    print_robot_loc_or(location,direction)
    print_obstacles_loc(domain['obstacles'])
    print_charge_info()
    print(' ')
    print_world(world)
    if fires() != []:
        fire_locations = ""
        for f in fires():
            fire_locations += "({},{})  ".format(f[0],f[1])
        print(' ')
        print('  ALARM!!! We have fires burning at '+fire_locations)

def start_fire():
    def is_valid_fire(cell):
        if is_black(cell) or \
                is_obstacle(cell) or \
                is_base(cell):
            return False
        return True
        
    cell = [np.random.randint(size),np.random.randint(size)]
    while not is_valid_fire(cell):
        cell = [np.random.randint(size),np.random.randint(size)]

    domain['fires'].append(list(cell))
    

plot_world(domain,location,direction)


while True:
    active_fires = len(fires())
    if active_fires < max_fires:
        if np.random.rand() < 0.1/(2**active_fires):
            start_fire()
            
    
    sens = get_sensors()
    if sens['batt'] == 'dead':
        break
    sensors_cad = '['+','.join([ 'sensor(' + s + ',' + sens[s] +')' for s in sens ])+'].'   # period. For prolog
    print(" Sensors: "+sensors_cad)
    f = open('tube','w')
    f.write(sensors_cad)

    f.close()
    
    if state == 'dead':
        print('dead')
        break
        
    f = open('tube')
    actions = f.readline() #input("Next move: ")
    f.close()
    print('Read '+actions)
    
    if process(actions) in ['end','dead']:
        print('ooooh!')
        break
    
    plot_world(domain,location,direction)
    

