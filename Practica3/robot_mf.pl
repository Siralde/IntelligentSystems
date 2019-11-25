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
 * Si estamos en baldosa negra y hay fuego:
 * la temperatura es equal es que lo tenemos a la izquierda o a la derecha, 
 * Hemos elegido girar a la derecha arbitrariamente
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
 * Como el temp marca equal y estamos en la 
 * base nos movemos de ella para buscar fuego
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


/*
 *
 * Si no hay fuego cuando sale de la base (temp = equal) se devuelve a la base
 *
 */
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
 * 
 * NOTA IMPORTANTE aqui añadimos como premisa que haya fuego debido a que si no lo hicieramos y solo 
 * dejaramos la regla siguiente se añadiria este estado cada vez, haciendo que el sistema no funcione
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

/*
 * Si hay fuego frente al robot, sabemos que hay fuego asi que añadimos un estado 
 * Que quiere decir que ademas de que estamos buscando fuego, hay fuego activo en este momento
 *
 */
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
 * NOTA: EN EL MUNDO DADO NO EXISTEN OBSTACULOS AL FRENTE DE LAS BALDOSAS NEGRAS POR LO TANTO ESTO NUNCA SE CUMPLE
 * EN EL CASO DE QUE SE CUMPLIERA ABRIA QUE MEJORAR ESTA REGLA PORQUE PUEDE QUE EL FUEGO ESTE JUSTO DETRAS DEL OBSTACULO
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
 * Si tenemos el fuego al de frente del robot pero no en la celda siguiente
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
 * x1, es la posicion inicial y X5 es la posicion final
 *
 *    |x5|x4| Nos paramos en x4 y comprobamos que hay en x5 con el estado checkear por fuego
 *    |--|x3|
 *    |x1|x2|
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

/*
 * 
 * x1, es la posicion inicial y x5 es la posicion final
 *
 *    |x5|x4| Viniendo de la regla anterior si x5 es fuego, el robot lo apaga y se devuelve a x1
 *    |--|x3|
 *    |x1|x2|
 * 
 */
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


/*
 * 
 * x1, es la posicion inicial y x5 es la posicion final
 *
 *    |x5|x4| Viniendo de la regla fuego_obstaculo_defrente_baldosa_normal 
 *    |--|x3| Si x5 no es fuego el robot se va a esa posicion
 *    |x1|x2|
 * 
 */
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



/****************FIN BUSCANDO FUEGO BALDOSA NORMAL*********************/


/********** BUSCANDO BASE BALDOSA NEGRA ***********/

/*
 * Si nos consiguimos una pared nos damos media vuelta y avanzamos tres pasos
 *
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


/*
 * si estamos en la baldosa negra y no hay nada al frente avanzamos
 */
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

/*
 * Si no se cumple ninguna de las anteriores simplemente giramos nuestro eje para cumplir alguna de las anteriores
 *
 */
rule girar_buscando_base_baldosa_negra:
[
  1: buscando_base_baldosa_negra,
  2: sensor(cell,black)
]
==>
[
  do([turnR])
].


/*
 * Si nos recargamos cambiamos de estado a buscar fuego
 *
 */
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
 * avanzamos, cambiamos de estado desde: baldosa normal a baldosa negra
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



/*
 * 
 * x5, es la posicion inicial y x1 es la posicion final
 *
 *    |x5|x4| Vamos de x5 a x2 y alli comprobamos si hay fuego o no 
 *    |--|x3| 
 *    |x1|x2|
 * 
 * NOTA IMPORTANTE: SI VOLVIENDO A BASE SALE UN FUEGO QUE ESTA JUSTO DETRAS DEL OBSTACULO QUE VAMOS LO APAGAMOS
 * Si no nos ponemos en x1
 *
 */
rule obstaculo_buscando_base_baldosa_normal:
  [
    1: buscando_base_baldosa_normal,
    2: sensor(cell,normal),
    3: sensor(light,normal),
    4: sensor(prox,true)
  ]
  ==>
  [
    do([turnL,fwd,turnR,fwd,fwd,turnR]),
    insert(checkear_fuego)
  ].


/*
 * 
 * x5, es la posicion inicial y x1 es la posicion final
 *
 *    |x5|x4| Estando en x2 si en x1 hay fuego los apagamos 
 *    |--|x3| 
 *    |x1|x2|
 *
 */
rule obstaculo_fuego_emergencia_buscando_base_baldosa_normal:
  [
    1: buscando_base_baldosa_normal,
    2: sensor(cell,normal),
    3: sensor(light,bright),
    4: sensor(prox,false),
    5: checkear_fuego
  ]
  ==>
  [
    do([put-out,fwd,turnL]),
    eliminate(5)
  ].

/*
 * 
 * x5, es la posicion inicial y x1 es la posicion final
 *
 *    |x5|x4| Estando en x2 si en x1 no hay fuego, avazamos a esa posicion y giramos a la izquierda
 *    |--|x3| 
 *    |x1|x2|
 *
 */
rule obstaculo_no_fuego_emergencia_buscando_base_baldosa_normal:
  [
    1: buscando_base_baldosa_normal,
    2: sensor(cell,normal),
    3: sensor(light,normal),
    4: sensor(prox,false),
    5: checkear_fuego
  ]
  ==>
  [
    do([fwd,turnL]),
    eliminate(5)
  ].

/*
 * Si devolviendome a la base aparece un fuego lo apago
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
