######################################################################
CC = gcc
LEX = flex
YACC = bison

LIB = -lc -lm
ELEX = compiler.l
EYACC = compiler.y
OBJ = compiler.o compiler.o compiler.o

SRC = compiler.c symtab.c
SRCL = compiler.flex.c
SRCY = compiler.tab.c #Se genera tambien un compiler.tab.h

BIN = compiler
LFLAGS = -n -o $*.c 
YFLAGS = -d -v -o $*.c
CFLAGS = -ansi -Wall -g
OTHERS = compiler.tab.h compiler.output

######################################################################

all : $(SRCL) $(SRCY)
	$(CC) -o $(BIN) $(CFLAGS) $(SRCL) $(SRCY) $(SRC)  $(LIB)

$(SRCL) : $(ELEX)	
	$(LEX) $(LFLAGS) $<

$(SRCY) : $(EYACC)
	$(YACC) $(YFLAGS) $<

clean : 
	rm -f *~ $(BIN) $(OBJ) $(SRCL) $(SRCY) $(OTHERS)

