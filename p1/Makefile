######################################################################
CC = gcc
LEX = flex
YACC = bison

LIB = -lc 
ELEX = calc.l
EYACC = calc.y
OBJ = calc.o calc.o calc.o

SRC = calc.c symtab.c
SRCL = calc.flex.c
SRCY = calc.tab.c #Se genera tambien un calc.tab.h

BIN = calc
LFLAGS = -n -o $*.c 
YFLAGS = -d -v -o $*.c
CFLAGS = -ansi -Wall -g
OTHERS = calc.tab.h calc.output

######################################################################

all : $(SRCL) $(SRCY)
	$(CC) -o $(BIN) $(CFLAGS) $(SRCL) $(SRCY) $(SRC)  $(LIB)

$(SRCL) : $(ELEX)	
	$(LEX) $(LFLAGS) $<

$(SRCY) : $(EYACC)
	$(YACC) $(YFLAGS) $<

clean : 
	rm -f *~ $(BIN) $(OBJ) $(SRCL) $(SRCY) $(OTHERS)

