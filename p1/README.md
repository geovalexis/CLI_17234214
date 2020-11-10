# PRACTICA 1: Calculadora
> **AUTOR**: Geovanny Risco <br/>
> **GRADO**: Doble Grado de Ingenería Informática y Biotecnología
## Requerimientos previos
Las versiones de los programas utilizados para la realizacion de éste proyecto son:
La siguiente práctica se ha realizado utilizando la imagen milax-debian v20200214 bajo el motor de virtualización de VirtualBox v6.1. De esta imagen se utilizaron las siguientes utilidades:
* flex v2.6.4
* bison v3.3.2
* gcc v8.3.0

## Especificaciones
Los 3 ficheros principales son:
* **calc.c**: main de la calculadora, se encarga de la ejecucion del flex y bison asi como de presentar cualquier error que puedan derivarse de estos.
* **calc.l**: implementación del análisis léxico (flex).
* **calc.y**: implementación de la gramática (bison).

A parte de éstos ficheros principales también existen otros que, aunque menos importantes, también son necesarios para el correcto funcionamiento del programa. Éstos son:
* **syntab.h y symtab.c** : header e implementación de la tabla de simbolos (symtab en este caso) respectivamente. Se trata de los mismos ficheros disponibles en el moodle pero ligeramente modificados.
* **Makefile** : script para ejecutar de manera automatizada todas los ficheros y utilidades necesarias para la compilación del programa.

## Decisiones de diseño
### Análisis léxico:
Creo que el código del flex es bastante claro por sí mismo. Los únicos detalles raras quizás que me gustaría aclarar son los siguientes:
* Considero que un símbolo ```-``` significa resta solo si no esta seguido de un número, ya que en este caso creo que es más acertado tratarlo como un número negativo en vez de como símbolo de resta.
* Devuelvo un token ```FIN DE SENTENCIA``` tanto en caso de que sea un salto de línea (```\n```) como un comentario. Ésto lo hago para que bison pueda saltarse los comentarios igual que cuando le llega un fin de sentencia despues de una expresión.
### Tabla de símbolos:
En el header he adaptado el tipo del ```sym_value_type``` a las necesidades de mi programa, tengo una structura del tipo union que contiene los 4 tipos de variables especificadas por el enunciado asi como un enumerado que me guarda el tipo correspondiente (gracias a esto puedo saber qué tipo de variable se está utilizando).
### Análisis sintáctico:
En este caso puede que el código no sea tan legible como en el flex, y esto es porque las acciones para cada gramática me ocupan un buen trozo de código. No obstante la mayor parte de éste código es bastante repetitivo y se encarga principalmente de comprobar el tipo y realizar las operaciones correspondientes respetando las reglas matemáticas y especificaciones del enunciado. No encapsulé todas éstas acciones en una función porque me dí cuenta de que cada operación tenía sus excepciones y al final ésto me dificultaría la implementación más que ayudarme (e igualmente tendría que tratar cada operación matemática por separado). 
***NOTA***: Todo lo que concierne al análisis sintáctico de operaciones booleanas no esta implementado porque no encontré la forma de ligarlo con las operaciones aritméticas sin desmontar toda la estructura que tenía hasta ahora, asi que decidí saltarméla y mejorar lo que tenía. No me daba tiempo a rehacer el esquema que había pensado hasta ese momento porque fui con el tiempo justo, para la próxima práctica me intentaré organizar mejor. 
## Ejecución
### 1. Compilacion
Para la compilación del programa es necesario ejecutar los siguientes comandos:
```bash
make all
```
Se generán diferentes ficheros intermedios pero el archivo que nos interesará es el que tiene de nombre ```calc```. Probablemente salten un monton de warnings que deberia de mirar e intentar solucionar para la próxima.
### 2. Ejecucion
Una vez compilado podremos ejecutar el programa mediante:
```bash
./calc input1.txt output1.txt
``` 
### 3. Limpieza (opcional)
En caso de que queramos limpiar todos los archivos resultantes de la compilación, realizar lo siguiente:
```bash
make clean
```
## Resultados
A modo de juego de pruebas tengo dos archivos llamados ```input1.txt``` y ```input2.txt```, cuya ejecución con la versión actual de programa debería de producir los resultados espeficados en ```output1.txt``` y ```output2.txt``` respectivamente. El ```input2.txt``` es el correspondiente al enunciado de la práctica aunque incompleto, solo están incluidas las partes que funcionan correctamente.
## Limitaciones (TODOs)
* Falta implementación de la parte de expresiones booleanas.
* Más de 30 conflictos shift/reduce, la mayoría producidos por la sentencia inicial. 
* Hay muchos potenciales errores de cálculo que no estan contemplados.
