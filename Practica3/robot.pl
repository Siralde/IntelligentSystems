:-[firerobot].

/* Predicates that this particular agent will use */
:-dynamic fact/1.
:-dynamic fire/1.
:-dynamic obstacles/1.
:-dynamic world_size/1.

/* Usually, we want all of them clean before starting... */
things_to_vanish([(fact,1),(fire,1),(obstacles,1),(world_size,1)]).

/* Facts that we want to be true before starting... */
initial_facts([at_start]).

/* This is the list of action that will be executed sequentially at the beginning of each cycle, even before than the test
   of the conditions in the LHS, so if these actions change the conditions, rule firing will be altered accordingly. 
   The actions must be prolog predicates to be invoked without arguments. */
starting_actions([read_sensors]).

/* Now, two things you must know:

   When the rule interpreter starts, the fact 'fact(at_start)' exists in the database so the condition
   at_start will succeed.
   Use it to set things up in one rule (the first to be applied) and then, erase it if you want (you SHOULD want...).

   Also, don't forget to add to the RHS of at least one rule the action insert(at_end) to
   let the robot (and the program) stop. Otherwise, your program will run forever... 
*/

rule stop:
  [1: at_end]
  ==>
  [do([stop])].

rule suicide:
  [1: sensor(batt,dead)]
  ==>
  [insert(at_end)].

rule init:
  [1: at_start]
  ==>
  [eliminate(1),
   true_as_is(world_size(10)),
   true_as_is(obstacles([[2,3],[7,8],[6,3]])),
   insert(no_fire)
  ].

/* REGLAS DE COMPORTAMIENTO
  
   LAS REGLAS QUE TIENEN QUE ADELANTE QUIERE DECIR QUE FUEGO ESTA EN LA CELDA DE AL FRENTE
   LAS REGLAS QUE TIENEN QUE DEFRENTE QUIERE DECIR QUE EL FUEGO ESTA AL MENOS 
    A DOS CELDAS AL FRENTE DEL ROBOT

 */

rule empieza:
  [
    1: no_fire,
    2: sensor(cell,base)
  ]
  ==>
  [
    insert(buscando_fuego_baldosa_negra),
    eliminate(1)
  ].


/********** BUSCANDO FUEGO BALDOSA NEGRA ***********/

/*
 * Si estamos en frente del fuego lo apagamos
 */
rule fuego_adelante_baldosa_negra:
  [
    1: buscando_fuego_baldosa_negra,
    2: sensor(temp,up),
    3: sensor(light,bright),
    4: sensor(cell,black)
  ] 
  ==>
  [ 
    do([put-out]),
    eliminate(1),
    insert(buscando_base_baldosa_negra)
  ].

/*
 * Como el temp marca equal y estamos en la 
 * base nos movemos de ella para buscar guego
 */
rule salir_base_baldosa_negra:
  [
    1: buscando_fuego_baldosa_negra,
    2: sensor(cell,base),
    3: sensor(temp,equal)
  ]
  ==>
  [
    do([fwd])
  ].


rule volver_base_baldosa_negra:
  [
    1: buscando_fuego_baldosa_negra,
    2: sensor(cell,black),
    3: sensor(temp,equal),
    4: notin(hay_fuego)
  ]
  ==>
  [
    do([turnR,turnR,fwd])
  ].

/*
 * Si estamos en baldosa negra y 
 * la temperatura es equal es que lo tenemos a la izquierda o a la derecha, 
 * giramos a la derecha
 */
rule fuego_a_los_lados_baldosa_negra:
  [
    1: buscando_fuego_baldosa_negra,
    2: sensor(cell,black),
    3: sensor(temp,equal),
    4: sensor(light,dark),
    5: hay_fuego
  ]
  ==>
  [
    do([turnR]),
    eliminate(5)
  ].


/*
 * Si estamos en baldosa negra y 
 * la temperatura esta down hacemos media vuelta, 
 * ya que tenemos el fuego detras nuestro
 */
 rule fuego_detras_baldosa_negra:
  [
    1: buscando_fuego_baldosa_negra,
    2: sensor(temp,down),
    3: sensor(light,notequal(bright)),
    4: sensor(cell,black)
  ]
  ==>
  [ 
    do([turnL,turnL])
  ].


/*
 * Si estamos en baldosa negra, la temperatura esta up, light es dark y no hay obstaculo
 * es que tenemos el fuego de frente del robot, asi que avanzamos por la linea negra
 * hata que temp sea equal.
 */
rule fuego_defrente_baldosa_negra:
  [
    1: buscando_fuego_baldosa_negra,
    2: sensor(cell,black),
    3: sensor(temp,up),
    4: sensor(prox,false),
    5: sensor(light,dark),
    6: hay_fuego
  ]
  ==>
  [
    do([fwd])
  ].
rule fuego_defrente_baldosa_negra:
  [
    1: buscando_fuego_baldosa_negra,
    2: sensor(cell,black),
    3: sensor(temp,up),
    4: sensor(prox,false),
    5: sensor(light,dark)
  ]
  ==>
  [
    do([fwd]),
    insert(hay_fuego)
  ].


/*
 * Si estamos en baldosa negra, la temperatura esta up y light es normal 
 * es que tenemos el fuego al menos a dos casillas al frente y tenemos que
 * salir de la linea negra, asi que avanzamos
 */
rule fuego_defrente_salir_de_baldosa_negra:
  [
    1: buscando_fuego_baldosa_negra,
    2: sensor(cell,black),
    3: sensor(light,normal),
    4: sensor(prox,false),
    5: sensor(temp,up)
  ]
  ==>
  [
    do([fwd]),
    eliminate(1),
    insert(buscando_fuego_baldosa_normal)
  ].

/*
 * Si estamos en baldosa negra, la temperatura esta up y ( light es dark y prox es dark)
 * es que tenemos el fuego al menos a dos casillas al frente y hay un obstaculo al frente
 * Asi que rodeamos al obstaculo de la siguiente manera:
 * 
 * X0, es la posicion inicial y X5 es la posicion final
 *
 *    |x5|x4|
 *    |--|x3|
 *    |x0|x2|
 * 
 */
rule fuego_obstaculo_defrente_baldosa_negra:
  [
    1: buscando_fuego_baldosa_negra,
    2: sensor(cell,black),
    3: sensor(light,normal),
    4: sensor(prox,true),
    5: sensor(temp,up)
  ]
  ==>
  [
    do([turnR,fwd,turnL,fwd,fwd,turnL,fwd,turnR]),
    eliminate(1),
    insert(fuego_defrente_baldosa_normal)
  ].

/****************************************************/


/********** BUSCANDO FUEGO BALDOSA NORMAL ***********/

/*
 * Si estamos en frente del fuego lo apagamos y damos media vuelta para volver
 */
rule fuego_adelante_baldosa_normal:
  [
    1: buscando_fuego_baldosa_normal,
    2: sensor(light,bright),
    3: sensor(cell,normal),
    4: notin(checkear_por_fuego)
  ] 
  ==>
  [ 
    do([put-out, turnR, turnR]),
    eliminate(1),
    insert(buscando_base_baldosa_normal)
  ].


/*
 * Si tenemos el fuego a mas de de frente a nosotros pero no en la celda siguiente
 * avanzamos
 */
rule fuego_defrente_baldosa_normal:
  [
    1: buscando_fuego_baldosa_normal,
    2: sensor(temp,up),
    3: sensor(light,normal),
    4: sensor(prox,false),
    5: sensor(cell,normal),
    6: notin(checkear_por_fuego)
  ] 
  ==>
  [ 
    do([fwd])
  ].


/*
 * Si estamos en baldosa negra, la temperatura esta up y ( light es dark y prox es dark)
 * es que tenemos el fuego al menos a dos casillas al frente y hay un obstaculo al frente
 * Asi que rodeamos al obstaculo de la siguiente manera:
 * 
 * X0, es la posicion inicial y X5 es la posicion final
 *
 *    |x5|x4|
 *    |--|x3|
 *    |x0|x2|
 * 
 */
rule fuego_obstaculo_defrente_baldosa_normal:
  [
    1: buscando_fuego_baldosa_normal,
    2: sensor(cell,normal),
    3: sensor(light,normal),
    4: sensor(prox,true),
    5: sensor(temp,up)
  ]
  ==>
  [
    do([turnR,fwd,turnL,fwd,fwd,turnL]),
    insert(checkear_por_fuego)
  ].

rule checkear_fuego_obstaculo_baldosa_normal:
[
  1: buscando_fuego_baldosa_normal,
  2: sensor(light,bright),
  3: sensor(prox,false),
  4: sensor(temp,up),
  5: checkear_por_fuego
]
==>
[
  do([put-out,turnL,fwd,fwd,turnR,fwd,turnL]),
  eliminate(5),
  eliminate(1),
  insert(buscando_base_baldosa_normal)
].

rule checkear_no_fuego_obstaculo_baldosa_normal:
[
  1: buscando_fuego_baldosa_normal,
  2: sensor(light,normal),
  3: sensor(prox,false),
  4: sensor(temp,up),
  5: checkear_por_fuego
]
==>
[
  do([fwd,turnR]),
  eliminate(5)
].



/****************************************************/


/********** BUSCANDO BASE BALDOSA NEGRA ***********/

/*
 * Esto son para volver a la base
 */
rule pared_defrente_baldosa_negra:
  [
    1: buscando_base_baldosa_negra,
    2: sensor(cell,black),
    3: sensor(prox,true)
  ]
  ==>
  [
    do([turnR,turnR,fwd,fwd,fwd])
  ].

rule avanzar_buscando_base_baldosa_negra:
  [
    1: buscando_base_baldosa_negra,
    2: sensor(cell,black),
    3: sensor(light,dark),
    4: sensor(prox,false)
  ]
  ==>
  [
    do([fwd])
  ].

rule girar_buscando_base_baldosa_negra:
[
  1: buscando_base_baldosa_negra,
  2: sensor(cell,black)
]
==>
[
  do([turnR])
].

rule recarga: 
  [
    1: buscando_base_baldosa_negra,
    2: sensor(cell,base)
  ]
  ==>
  [
    insert(buscando_fuego_baldosa_negra),
    eliminate(1)
  ].

/************************************************/


/********** BUSCANDO BASE BALDOSA NORMAL ***********/



/**
 * Si estamos en baldosa normal y al frente no hay baldosa negra ni obstaculo ni pared 
 * avanzamos
 */
rule avanzar_buscando_base_baldosa_normal:
  [
    1: buscando_base_baldosa_normal,
    2: sensor(cell,normal),
    3: sensor(light,normal),
    4: sensor(prox,false)
  ]
  ==>
  [
    do([fwd])
  ].

/**
 * Si estamos en baldosa normal y al frente hay baldosa negra 
 * avanzamos, cambiamos de baldosa normal a baldosa negra
 */
rule avanzar_buscando_base_baldosa_normal:
  [
    1: buscando_base_baldosa_normal,
    2: sensor(cell,normal),
    3: sensor(light,dark),
    4: sensor(prox,false)
  ]
  ==>
  [
    do([fwd, turnR]),
    eliminate(1),
    insert(buscando_base_baldosa_negra)
  ].



rule obstaculo_buscando_base_baldosa_normal:
  [
    1: buscando_base_baldosa_normal,
    2: sensor(cell,normal),
    3: sensor(light,normal),
    4: sensor(prox,true)
  ]
  ==>
  [
    do([turnL,fwd,turnR,fwd,fwd,turnR,fwd,turnL])
  ].


/*
 * Hubo una simulacion en la cual justo acababa de apagar un incendio
 * y devolviendome a la base salio un nuevo incendio en mi camino
 * Cuando me estoy devolviendo a la base no apago incendios. Por esta 
 * razon creo esta regla
 */
rule apagar_fuego_buscando_base_baldosa_normal:
  [
    1: buscando_base_baldosa_normal,
    2: sensor(cell,normal),
    3: sensor(light,bright),
    4: sensor(prox,false)
  ]
  ==>
  [
    do([put-out])
  ].

  /*****************************************************/
