/*
  forwardchain

  A simple inference engine for a system of rules and facts to control an agent written in Prolog.
  Rules about the agent's behaviour, as long as predicates to manage its sensorial system and to
  implement its simulated (or real) actions are supposed to be loaded from a separate file.

  Rule structure is:

  regla <rule_identifier>:
	[<antecedent_number>: <clause>,
	 <antecedent_number>: <clause>
	 ...
	]
	==>
	[<action>,
	 <action>,
	 ...
	].

  where:

  <rule_identifier> is any prolog atom (it may be a number) as long as it is unique for each different rule
			(it's the responsibility of the rule's writer to check this).

  <antecedent_number> is a integer number that takes consecutive values from 1 and up for each rule.

  <clause> is a prolog clause which makes sense for this agent, or any prolog clause that can be added by an
	   insertion action (see below). The set of clauses that make sense for each particular agent (usually,
	   clauses of type sensor(...)) must be defined in a file that will be loaded when passed as argument
	   to main (see below).

  The list of antecedents is enclosed by [] and separated by commas but no comma should be used for a single antecedent.

  <action> is a valid action. Valid actions are exclusively:

  true_as_is(X) which will insert X in the prolog database. There is no action to remove X.
		Using true_as_is you could even add predicates to modify not only agent's behaviour but also agent's RULES of behaviour.
		Its main purpose, nevertheless, is to introduce descriptions of a static world.

  insert(X) which will add a clause of the form fact(X) in the prolog database when invoked. This is equivalent
	    to say that X has become true, and it will remain so until X is removed by eliminate.

  eliminate(<antecedent_number>) which will eliminate clause fact(H) from the prolog database when invoked, being H the
				fact that was numbered with <antecedent_number> in the head of THIS rule (i.e.: the rule
				that invoked eliminate).

  do([atomic_action1,...])	which makes the agent execute one by one each action of the passed list.
				Obviously, each atomic action must be known by the agent. This is managed by predicate take_action.

  Predicate take_action(+Atomic_action) is assumed to exist and it is written (or has been consulted by) the agent definition file.
*/


/* Definition of the operators used to write rules. */

:-op(810,fx,rule).     /* Used to define rules. This is the operator with the highest precedence */
:-op(800,xfx,==>).     /* Used to separate the left hand side from the right hand side of a rule. 
			   Its precedence follows in importance to that of 'rule' */
:-op(500,xfy,:).       /* Used  to separate the antedent number and the clause in rule antecedents */

/* annihilate_all(+List)
	Predicate to be called at start (by clean_to_start) with the purpose of cleaning the database a list of predicates that may have
	remained as a result of a provious execution
*/
annihilate_all([]):-
	!.
annihilate_all([(F,N)|Tail]):-
	annihilate(F,N),
	annihilate_all(Tail).

/* annihilate(F,N)
	Auxiliary predicate to eliminate from the database all the clauses of a predicate with functor F and arity N.
	It you are wondering why to write this predicate instead of just using retractall(F,N), ASK TO THE SWI-PROLOG
	designers WHAT IN HELL did they do with the implementation of retractall, and why doesn't work.
*/
annihilate(F,N):-
	functor(T,F,N),
	T,
	!,
	retract(T),
	annihilate(F,N).
annihilate(_,_).

/* Some predicates needed to stablish succesful communication with the external agent. */
:-dynamic pending_actions/1.
:-dynamic nothing_to_read/0.

/* add_initial_facts(+List)
	Predicate to be called at start (by clean_to_state) with the purpose of adding one or more facts that the user wants
	to add, mainly for the purpose of making the initial rule fire.
*/
add_initial_facts([]):-
	!.
add_initial_facts([F|Tail]):-
	assert(fact(F)),
	add_initial_facts(Tail).

/* clean_to_start
	Predicate to be called at start by main. It looks at predicates things_to_vanish and initial_facts to know
	what the user wants to clean and what he wants to add before the rule engine starts running.
*/
clean_to_start:-
	annihilate(pending_actions,1),
	assert(pending_actions([])),
	annihilate(nothing_to_read,0),
	things_to_vanish(Lv),
	annihilate_all(Lv),
	initial_facts(Lf),
	add_initial_facts(Lf),
	!.

/* main(+Agent_definition_file)
	The main program. The agent definition file must contain:
	 * All predicates or clauses that define the sensors
	 * An implementation of predicate take_action for each elementary actions supported by the agent
	 * The rules (in the formerly described format) that will make the agent "intelligent" (well, more or less....)
*/
main(Agent_definition_file):-
	/* The rules, that thanks to the previous operator definitions are valid prolog clauses, are loaded from the file*/
	[Agent_definition_file],
	clean_to_start,
	/* The system is invoked from the current state of the database which will normally be set by the first rule to fire. */
	motor(0,true),
	!.

/* main(+Agent_definition_file,_)
	Variant to say to main we don't want to wait for key.
*/
main(Agent_definition_file,_):-
	[Agent_definition_file],
	clean_to_start,
	motor(0,false),
	!.

/* execute_starting_actions
	This predicates checks if the user has defined any list of actions that must be executed just at the beginning of each rule.
	It checks the predicate staring_actions to know which ones (if any) and executing them.
*/
execute_starting_actions:-
	starting_actions([]),
	!.
execute_starting_actions:-
	starting_actions(ListOfActions),
	process_starting_actions(ListOfActions).

process_starting_actions([]):-
	!.
process_starting_actions([H|L]):-
	H,
	process_starting_actions(L).

list_facts:-
	bagof(F,fact(F),L),
	!,
	writeln('Los hechos ciertos actualmente son: '),
	print_list_of_facts(L).
list_facts:-
	writeln('No hay en este momento ningún hecho cierto en la base de datos.'),
	!.

print_list_of_facts([]):-
	flush_output,
	!.

print_list_of_facts([F|T]):-
	write('        '),writeln(F),
	print_list_of_facts(T).

wait(true):-
	!,
	write('Pulsa tecla para continuar... '),
	get_single_char(_),
	nl.

wait(_).

/* motor(+NumCycle,+WaitKey).
	It executes a single forward-chain step of the inference engine.
	Its last cluse calls itself so more steps goes on.
	NumCycle is the number of this cycle from the beginning.
	WaitKey is supposed to be true or false for waiting for a key after each cycle or not. */

motor(NumCycle,WaitKey):-
	execute_starting_actions,
	write('Ciclo '),
	writeln(NumCycle),
	list_facts,
	/* Calling a rule, as a prolog clause, doesn't do anyhting. It just checks that the rule is present as a prolog clause and 
	   instantiates the variables ID, LHS and RHS to the respective parts of the rule. */
	call(rule ID: LHS ==> RHS),
	/* check_if_it_fires succeed if the rule fires. This means that the LHS of the rule (i.e.: each of its antecedents sequentially) suceeds.
	   If not, check_if_it_fires will fail which means the current rule cannot be applied. 
	   In this case 'call' is retried with another rule. 
	   If no rule can be applied, motor fails here and goes to its next clause, which just makes it suceed. */
	check_if_it_fires(LHS),
	!,
	write('Se aplicará la regla con identificador '), write(ID), nl,
	/* But, if the rule fires, there is no way to restrain. The RHS will be executed, which will alter definitively the database. 
	   This is what 'process_RHS' does. The LHS is passed, too, since the RHS may contain actions to eliminate some facts mentioned
	   in it (and to which we referred by its number). */
	process_RHS(RHS,LHS),
	wait(WaitKey),
	writeln('================================================================='),
	/* and motor is invoked to search for an applicable rule. */
	/* Notice that the first rule found that can be applied IS applied (forward chaining).
	   If this behaviour does not please you, implement a system of states with a clause state(....) in the LHS of the
	   required rule and actions eliminate(..) and insert(state(...)) in the RHS to change the agent's internal state. */
	!,
	NextCycle is NumCycle+1,
	motor(NextCycle,WaitKey).

/* This is here for the case in which no more rules can be applied and motor must suceed so that main can suceed and finish. */
motor(Num,_):-
	/* motor invokes itself until no rule can be applied, and then succeeds. When this happens the current state of the database
	  (i.e.: things that are present into the database as fact(..) and therefore known to be true) are listed, for user's sake. */
	write('Después de '),
	write(Num),
	writeln('ciclos, no se puede aplicar ninguna regla. El programa acaba.'),
	flush_output,
	take_action(end),
	abort.

/* check_if_it_fires(+ListOfFacts)
	It gets a instantiated list of facts and suceeds if and only if all of them are present in the database as fact(X)
*/
check_if_it_fires([]):-
	!.
check_if_it_fires([_ : Fact | TailLHS]) :-
    functor(Fact,sensor,2),
    arg(1,Fact,Stype),
    arg(2,Fact,notequal(Sval)),
    /* write('Checking that sensor '),write(Stype),write(' has not the value '),writeln(Sval), */
    not(fact(sensor(Stype,Sval))),
    /* writeln('... which is currently true.'), */
	check_if_it_fires(TailLHS).
check_if_it_fires([_ : Fact | TailLHS]) :-
    functor(Fact,notin,1),
    arg(1,Fact,State),
    /* write('Checking that '),write(State),writeln(' is not currently true.'), */
    not(fact(State)), 
    /* writeln('... and it is certainly no true.'), */
	check_if_it_fires(TailLHS).
check_if_it_fires([_ : Fact | TailLHS]) :-
	fact(Fact),
	check_if_it_fires(TailLHS).


/* process_RHS(+ListOfActions)
	It gets a instantiated list of actions and executes sequentially all of them.
	At the end, it flushes the pending actions (i.e.: it sends them to the python program through the tube).
*/
process_RHS([],_):-
	flush_actions,
	!.
process_RHS([Head|Tail],LHS) :-
	process_atomic_action(Head,LHS),
	process_RHS(Tail,LHS).

/* process_atomic_action(+Action)
	Auxiliary predicate that takes a instantiated action and executes it according to its type.
*/

/* action of type read just reads a term from the console. */
process_atomic_action(read(X),_):-
	writeln('Escribe el hecho que vamos a aceptar como cierto (para terminar, escribe fin.) '),
	read(X),
	!.

/* action of type write just writes a string in the console for user's information. */	
process_atomic_action(write(X),_):-
	writeln(X),
	!.
/* action of type true_as_is(X) adds the term or clause X to the prolog database. */
/* OJO: el retract... */
process_atomic_action(true_as_is(X),_):-
	assert(X),
	!.

/* action of type insert adds a term to the database as a clause fact(...). */
process_atomic_action(insert(Fact), _):-
	assert(fact(Fact)),
	!.

/* action of type eliminate_all removes all clause of the form fact(Term) mentioned in the LHS */
process_atomic_action(eliminate_all,LHS):-
	eliminate_all_LHS_facts(LHS),
	!.

/* action of type eliminate(X) removes a clause of the form fact(Term). X must be a number. */
process_atomic_action(eliminate(X),LHS):-
	number(X),
	eliminate_LHS_fact(X,LHS),
	!.

process_atomic_action(eliminate(_),_):-
	writeln('Error: ha invocado la acción eliminate(X) pero X no es un número de antecedente.'),
	abort.

/* action of type do(List) execute each indivual action of List */
process_atomic_action(do([H|T]),_):-
	process_one_by_one([H|T]),
	!.

process_atomic_action(Action,_):-
	write('Error: ha invocado una accion no conocida: '),write(Action),nl,
	writeln('Las acciones conocidas son insert(_), eliminate(_), eliminate_all o do(List).'),nl,
	abort.

process_one_by_one([]):-
	!.
process_one_by_one([AC|REM]):-
	/* As stated before, take_action(+Atomic_action) is assumed to exist... */
	take_action(AC),
	process_one_by_one(REM).

/* eliminate_LHS_Fact(+X, +LHS)
	Auxiliary predicate to remove from the database the antecedent with certain number in the left hand side of a rule.
	X must be instantiated to an integer number bigger or equal than 1
	LHS must be instantiated to the left hand side of a rule.
*/

/* Base case: we have found the antecendent with the requested number. */
eliminate_LHS_fact(X, [X : Fact|_]) :-
	!,
	retract_if_it_exists(fact(Fact)).

/* Alternative case: we go on searching to find the requested number. */	
eliminate_LHS_fact(X, [Y : _|LHSTail]) :-
	Y \= X,
	!,
	eliminate_LHS_fact(X, LHSTail).

/* Fail case: the rule was badly written. There is no antecendet with the number the actions asks to remove. */
eliminate_LHS_fact(N,_):-
	write('Error: intentas eliminar el antecedente '),write(N),write(' en una regla que no tiene tal antecedente.'),nl,
	flush_output,
	abort.

/* eliminate_all_LHS_facts(+LHS)
	Auxiliary predicate to remove all the facts of the current rule. Invoked by the action eliminate_all.
*/
eliminate_all_LHS_facts([]):-
	!.
eliminate_all_LHS_facts([_ : Fact | LHSTail]):-
	retract_if_it_exists(Fact),
	eliminate_LHS_facts(LHSTail).

/* retract_if_it_exits(+Fact)
	Auxiliary predicate to get rid of a clause of type fact(Fact) if it exists in the prolog database.
	It should exist unless the rule that invoked it was incorrectly written, but just in case, we test and abort the
	program if not.
*/

retract_if_it_exists(Fact):-
	functor(Fact,sensor,_),
	writeln('Aviso: no se puede eliminar una cláusula de tipo sensor(...). Los sensores vienen del exterior y cambian por sí mismos.'),
	!.

retract_if_it_exists(Fact):-
	retract(Fact),
	!.

retract_if_it_exists(Fact):-
	writeln('Error: intentas eliminar el hecho:'),
	writeln(Fact),
	write('pero ninguna cláusula '),write(Fact),write(' existe actualemente en la base de datos.'),
	flush_output,
	abort.

