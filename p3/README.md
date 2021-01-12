# PRACTICA 3: Creación de un lenguaje completo
> **AUTOR**: Geovanny Risco

> **GRADO**: Doble Grado de Ingenería Informática y Biotecnología
## Requerimientos previos
La siguiente práctica se ha realizado utilizando la imagen milax-debian v20200214 bajo el motor de virtualización de VirtualBox v6.1. De esta imagen se utilizaron las siguientes utilidades:
* flex v2.6.4
* bison v3.3.2
* gcc v8.3.0

## Especificaciones
Los 3 ficheros principales son:
* **compiler.c**: main del compilador. Se encarga de la ejecucion del flex y bison asi como de presentar cualquier error que puedan derivarse de estos.
* **compiler.l**: implementación del análisis léxico (flex).
* **compiler.y**: implementación de la gramática (bison).

A parte de éstos ficheros principales también existen otros que, aunque menos importantes, también son necesarios para el correcto funcionamiento del programa. Éstos son:
* **syntab.h y symtab.c** : header e implementación de la tabla de simbolos (symtab en este caso) respectivamente. Se trata de los mismos ficheros disponibles en el moodle pero ligeramente modificados.
* **Makefile** : script para ejecutar de manera automatizada todos los ficheros y utilidades necesarias para la compilación del programa.

## Decisiones de diseño
### Análisis léxico:
Practicamente igual que en la anterior entrega pero con las respectivas definiciones para los literales booleanos, sentencias iterativas (while, for, do-until) y condicionales (if, if-else) añadidas. También es importante destacar de esta parte que a la hora de parsear los identificadores diferencio entre ID booleano (ID_BOOL), ID aritmético (ID_ARITM) e ID nuevo (ID). Este último caso se trata de un ID del cual no sabemos su tipo porque no se ha inicializado todavía dado que es un identificador nuevo (el tipo se asigna en la gramática).

### Tabla de símbolos:
Además de las variables ```lloc``` y ```tipo```, se han añadido dos variables más a la structura del ```sym_value_type```: 
* ```agregado```: se trata de una string que contendrá el valor "agregado" de una operación. Aqui se guardarán los resultados de aquellas operaciones que se puedan realizar en tiempo de ejecución (literales enteros o reales). Si esta variable esta a ```NULL```, no será utilizada, ya que se asume que no hay ningún valor agregado, pero por el contrario si tiene algún valor se priorizará utilizar esta variable antes que ```lloc```.
* ```is_id```: esta variable es necesaria para evitar intentar realizar operaciones en tiempo de ejecución con identificadores, ya que éste no es el objetivo del compilador. No he encontrado otra forma de realizar esta omprobación ya que mi gramática no diferencia entre ID_aritm o cualquier otro literal aritmético (INTEGER o REAL).

### Análisis sintáctico:
En este caso la parte aritmética se encuentra prácticamente igual que en la anterior entrega. Mantengo las funciones ```emet_calculation``` y ```emet_salto_condicional```, las cuales me ahorran mucho código entre medio de las declaraciones. No obstante, las he mejorado y testado signficamente respecto a la anterior práctica, e incluso ahora desde ````emet_calculation```` llamo a una nueva función llamada ```calcula_literal```, la cual se encarga de realizar las correspondientes operaciones aritméticas cuando ambos son literales enteros o de coma flotante.
Toda la parte de expresiones booleanas, sentencias iterativas y condicionales se encuentra implementado tal cual lo hemos visto en clase. Lo único a destacar tal vez sea que yo he decido poner los literales booleanos (true y false) en la parte aritmética, de forma que las asignaciones de realizan de forma directa, y despues en la parte de expresiones booleanas trato los identificadores booleanos correctamente.
## Ejecución
### 1. Compilacion
Para la compilación del programa es necesario ejecutar los siguientes comandos:
```bash
make all
```
Se generán diferentes ficheros intermedios pero el archivo principal que es el que tiene de nombre ```compiler``` (sin extensión). Probablemente salten un monton de warnings pero la mayor parte son debido a temas de C y sus limitaciones. No debería de saltar ningún error de shift/reduce.
### 2. Ejecucion
Una vez compilado podremos ejecutar el programa mediante:
```bash
./compiler input1.txt output1.txt
``` 
### 3. Limpieza (opcional)
En caso de que queramos limpiar todos los archivos resultantes de la compilación, realizar lo siguiente:
```bash
make clean
```
## Resultados
A modo de juego de pruebas tengo 4 ficheros de test:
* ```input1_operaciones_aritmeticas.txt```: operaciones aritméticas tanto de literales como de identificadores y combinados.
* ```input2_ejemploP2.txt```: input de ejemplo del enunciado de la práctica 2.
* ```input3_ejemploP3.txt```: input de ejemplo del enunciado de la práctica 3.
* ```input4_otros.txt```: pruebas variadas.

## Limitaciones
* Podría tratar y mostrar más información sobre errores.
* De las partes opcionales solo están implementadas la evaluación de variables booleanas y de expresiones que solo involucren literales, el resto no estan implementadas. 
