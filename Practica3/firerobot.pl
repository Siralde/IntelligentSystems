%%%%%%%%%%%%%%%%%%%%%%%%%
% CELL SENSOR

/* sensor(+Sensor_type,+Detected_event)
	It suceeds if a sensor of Sensor_type, which must be passed instantiated, has detected an event of a given type
	(which must be passed instantiated, too). 

	Types of sensors are exclusively the following:
	- cell (to detect the type of cell the robot is over)
	- temp (to detect the temperature)
	- prox (to detect proximity to an obstacle)
	- light (to detect the type of the cell just in front of the robot)
	- batt (to detect the state of the battery).

	Type of events for each sensor are as follows:
	- For cell: 	base --> robot is on the base, i.e., recharging
			black --> robot is on  black square (path to the recharge station)
			normal --> robot is on a usual cell.
	- For temp:	equal --> robot is on the base, and therefore the temperature is as before
			up --> robot is either in front of the base or looking at the fire.
			down --> robot is back to the fire
	- For prox:	true --> robot is just in front of either, an obstacle or a wall
			false --> there is nothing solid (either obstacle or wall) in front of the robot.
	- For light:	dark --> the cell in front of the robot is either a wall or a black cell (path to the recharge station)
			bright --> the robot is in front of the fire
			normal --> none of the situations above
	- For batt:	high --> up to 10 time steps have elapsed since last recharge
			medium --> between 11 and 29 steps have elapsed since last recharge
			low --> between 30 and 50 steps have elapsed since last recharge
			dead --> 50 or more cycles have elapsed since last recharge. The robot can't move anymore. 
*/

/* assert_sensorial_facts(+List)
	Auxiliary predicate to add to the prolog database the fact(...) clauses to reflect the current readings of the sensors.
*/
assert_sensorial_facts([]):-
	!.
assert_sensorial_facts([sensor(S,V)|Rest]):-
	assert(fact(sensor(S,V))),
	!,
	assert_sensorial_facts(Rest).
assert_sensorial_facts([fire(Where)|Rest]):-
	assert(fire(Where)),
	!,
	assert_sensorial_facts(Rest).

/* forget_sensors
	Auxiliary predicate invoked at the beginning of each cycle to clean the database of all facts related to sensorial information
	before it is updated by the new values coming from the real (well, simulated...) robot (yeah, it's a python progam, I know...).
*/
forget_sensors:-
	bagof((S,V),fact(sensor(S,V)),L),
	!,
	kill_sensors(L).
/* This is to make forget_sensors suceed in case no fact(sensor(...)) clause is found. */
forget_sensors.

/* kill_sensors
	Auxiliary predicate to really erase from the database all the fact(sensor(...)) clauses currently present.
*/
kill_sensors([]):-
	!.
kill_sensors([(S,V)|L]):-
	retract(fact(sensor(S,V))),
	kill_sensors(L).

read_sensors:-
	nothing_to_read,
	!.
read_sensors:-
	open('/Users/ajgs/Desktop/SI/dev/Practica3/tube',read,Fd),
	read(Fd,SensorList),
	close(Fd),
	/* The old sensor readings are forgotten. assert_sensorial_facts will substitute them by the new values */
	forget_sensors,
	assert_sensorial_facts(SensorList),
	!.

%%%%%%%%%%%%%%%%%%%%%%%%%
% ACTIONS

add_to_pending(Action):-
	pending_actions(ListPending),
	!,
	append(ListPending,[Action],NewList),
	retract(pending_actions(ListPending)),
	assert(pending_actions(NewList)).

/* take_action(+Atomic_action)
	Predicate to execute each possible atomic action.

	Atomic actions allowed for this robot are:

	- stop: It aborts the program.
	- turnL: It changes the direction of advance of the robot making it turn 90 degrees to the left. This consumes one battery cycle.
	- turnR: It changes the direction of advance of the robot making it turn 90 degrees to the right. This consumes one battery cycle.
	- fwd: It changes the position of the robot making it advance one cell in its current direction of advance.
		If the robot is touching a wall or an obstacle, it does not move. This consumes one battery cycle IN ANY CASE.
	- put-out: It extinguishes the fire but only if it is just in front of the robot. This consumes four battery cycles.
*/

take_action(stop):-
	writeln('Fin del programa (pero no del simulador python).'),
	abort.

take_action(end):-
	writeln('Enviando [end] al simulador...'),
	open('/Users/ajgs/Desktop/SI/dev/Practica3/tube',write,Fd),
	write(Fd,'[end].'),
	close(Fd),
	!.

take_action(turnL):-
	add_to_pending(turnL),
	!.

take_action(turnR):-
	add_to_pending(turnR),
	!.

take_action(fwd):-
	add_to_pending(fwd),
	!.
	
take_action(put-out):-
	fire(F),
	retract(fire(F)),
	add_to_pending(put-out),
	!.

take_action(put-out):-
	add_to_pending(put-out),
	!.

flush_actions:-
	pending_actions([]),
	!,
	writeln('Ninguna acción enviada en este ciclo.'),
	assert(nothing_to_read).

flush_actions:-
	pending_actions(ListPending),
	ListPending=[_|_],
	!,
	annihilate(nothing_to_read,0),
	open('/Users/ajgs/Desktop/SI/dev/Practica3/tube',write,Fd),
	write(Fd,ListPending),
	close(Fd),
	write('Lista de acciones enviadas: '),
	writeln(ListPending),
	retract(pending_actions(ListPending)),
	assert(pending_actions([])),
	!.


