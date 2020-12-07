# PRACTICA 1: Calculadora
> **AUTOR**: Geovanny Risco <br/>
> **GRADO**: Doble Grado de Ingenería Informática y Biotecnología
## Requerimientos previos
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
* Devuelvo un token ```FIN DE SENTENCIA``` para identificar correctamente cuando acaba una sentencia y tambien poder saltarme las lineas en blanco y comentarios.
* Devuelvo 3 tipos de identificadores: ID, ID_ARITM y ID_BOOL. Cuando un identificador no está en la tabla de símbolos (nuevo identificador) devuelvo ID y sino, obtengo el tipo que es y devuelvo ID_BOOL en caso de que sea un booleano y ID_ARITM en caso contrario.
### Tabla de símbolos:
En el header he adaptado el tipo del ```sym_value_type``` a las necesidades de mi programa, tengo una structura del tipo union que contiene los 4 tipos de variables especificadas por el enunciado asi como un enumerado que me guarda el tipo correspondiente (gracias a esto puedo saber qué tipo de variable se está utilizando).
### Análisis sintáctico:
En este caso puede que el código no sea tan legible como en el flex, y esto es porque las acciones para cada gramática me ocupan un buen trozo de código. No obstante la mayor parte de éste código es bastante repetitivo y se encarga principalmente de comprobar el tipo y realizar las operaciones correspondientes respetando las reglas matemáticas y especificaciones del enunciado. No encapsulé todas éstas acciones en una función porque me dí cuenta de que cada operación tenía sus excepciones y al final ésto me dificultaría la implementación más que ayudarme (e igualmente tendría que tratar cada operación matemática por separado). 
En cuando al concatenación de los argumentos me gustaría destacar que me dio muchos problemas y todavía es propenso a bugs. Utilizo una [estrategia](https://stackoverflow.com/questions/29087129/how-to-calculate-the-length-of-output-that-sprintf-will-generate#:~:text=call.&text=You%20can%20call%20int%20len,counting%20the%20terminating%20'%5C0'%20) un tanto rebuscada para obtener el tamaño del buffer ya que de aquí me provenían la mayor parte de los problemas, pero bueno, supongo que esto son cosas de C. (<br/>
## Ejecución
### 1. Compilacion
Para la compilación del programa es necesario ejecutar los siguientes comandos:
```bash
make all
```
Se generán diferentes ficheros intermedios pero el archivo que nos interesará es el que tiene de nombre ```calc```. Probablemente salten un monton de warnings pero todos estos son debido a temas ajenos a la sintaxis y grámatica implementada.
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
A modo de juego de pruebas tengo dos archivos llamados ```input1.txt``` y ```input2.txt```, cuya ejecución con la versión actual de programa debería de producir los resultados espeficados en ```output1.txt``` y ```output2.txt``` respectivamente. El ```input2.txt``` es el correspondiente al enunciado de la práctica aunque con la penúltima sentencia ligeramente modificada (he quitado el identificado b ya que es un booleano y daría sintax error, no se si está a posta o sin querer) para obtener un output correcto.
## Limitaciones (TODOs)
* Potenciales errores de cálculo que no estan contemplados.
* Se podrían mostrar mas posibles errores.
* No estan implementadas las funciones opcionales.
