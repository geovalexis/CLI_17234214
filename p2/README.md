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
* **compiler.c**: main de la calculadora, se encarga de la ejecucion del flex y bison asi como de presentar cualquier error que puedan derivarse de estos.
* **compiler.l**: implementación del análisis léxico (flex).
* **compiler.y**: implementación de la gramática (bison).

A parte de éstos ficheros principales también existen otros que, aunque menos importantes, también son necesarios para el correcto funcionamiento del programa. Éstos son:
* **syntab.h y symtab.c** : header e implementación de la tabla de simbolos (symtab en este caso) respectivamente. Se trata de los mismos ficheros disponibles en el moodle pero ligeramente modificados.
* **Makefile** : script para ejecutar de manera automatizada todas los ficheros y utilidades necesarias para la compilación del programa.

## Decisiones de diseño
### Análisis léxico:
Creo que el código del flex es bastante claro autoexplicativo. A parte de que he borrado los tokens de de booleanos y demás cosas que no necesitaba, varía muy poco respecto a la entrega anterior. El único detalle a tener en cuenta es:
* Devuelvo un token ```FIN DE SENTENCIA``` para identificar correctamente cuando acaba una sentencia y tambien poder saltarme las lineas en blanco y comentarios.

### Tabla de símbolos:
El archivo ```symtab.h``` si que cambia ligeramente respecto a la entrega anterior. Esta vez no tengo una estructura union segun el tipo de variable, ya que ahora el compilador no va a realizar las operaciones sino que simplemente se va encargar de especificar en C3A la operación a realizar junto a los valores asignados, y por tanto tan solo necesito guardar el "valor" o "nombre" de la variable en cuestión. Para ello tengo una variable llamada ```lloc``` que es del tipo string (```char*``` en C), y tambien un enumerado que me indica el datatype de la variable.
### Análisis sintáctico:
Es este caso me gustaría destacar que tengo dos funciones que me hacen la mayor parte del trabajo: ```emet_calculation``` y ```emet_salto_condicional```. Estas funciones comprueban el tipo y emiten (con la función ```emet```) el C3A correspondiente. De esta manera no tengo tanto código repetido y puedo reaprovechar el código (en la anterior entrega no podía hacer esto por el tema de las operaciones). 
El resto de funciones y variables estan práticamente igual a lo explicado en clase. Es posible que algunas sentencias no tenga una funcionalidad clara en esta entrega, pero esto es porque las he dejado preparadas para la siguiente entrega.
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
A modo de juego de pruebas tengo 3 archivos llamados ```input1.txt```, ```input2.txt``` y ```input3.txt```, cuya ejecución con la versión actual de programa debería de producir los resultados espeficados en ```output1.txt```, ```output2.txt``` y ```output3.txt``` respectivamente. El ```input1.txt``` es el correspondiente al enunciado de la práctica. Los otros dos son pruebas aleatorias de funcionamiento (en los comentarios de cada input se indica la intención de cada prueba).
## Limitaciones (TODOs)
* Es posible que se puedan tratar y especificar mas posibles errores.
* No estan implementadas las funciones opcionales.
