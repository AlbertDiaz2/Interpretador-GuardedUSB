
Autores: Albert Díaz      11-10278
         Moisés González  11-10406

Para generar el parser:
racc parser.y -o parser.r

Y ejecutar
./guardedusb nombreArchivo.gusb

Distribuccion de archivos:

- lexer.rb: 
	
		Contiene el analizador lexicografico junto con las funciones necesarias para reconocer
	los tokens que presente un archivo con terminacion .gusb.

- parser.y:

		Genera el paser.rb con la informacion proveniente del arbol sintactico abstracto y de
	las tablas de simbolos, ademas de poseer la gramatica del programa.

- AST.rb:

	 	Archivo con todas las funciones requeridas para crear y RMr el arbol sintactico abstracto.

- SymTable.rb:

		Contiene todaslasfunciones necesarias para crear las tablas de simbolos y llevar un adecuado
	control de ellas.

- guardedusb:

	archivo ejecutable.

Ultima fecha de modificacion: 5-12-2019.