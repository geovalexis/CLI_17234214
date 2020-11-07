######################################################################
# 
#
#                           Compiladors I 
#             
#			 Jordi Castellà Roca
#
#                            Makefile
#            
#		            Curs 06/07
#  
######################################################################

# General defines
CC = gcc
LEX = flex
YACC = bison
LIB = -lc  #-lfl 
ELEX = exemple7l.l
EYACC = exemple7y.y
OBJ = exemple7.o exemple7y.o exemple7l.o
SRC = exemple7.c
SRCL = exemple7l.c
SRCY = exemple7y.c
BIN = exemple7
LFLAGS = -n -o $*.c 
YFLAGS = -d -v -o $*.c
CFLAGS = -ansi -Wall -g
OTHERS = exemple7y.h exemple7y.output

######################################################################

all : $(SRCL) $(SRCY)
	$(CC) -o $(BIN) $(CFLAGS) $(SRCL) $(SRCY) $(SRC)  $(LIB)

$(SRCL) : $(ELEX)	
	$(LEX) $(LFLAGS) $<

$(SRCY) : $(EYACC)
	$(YACC) $(YFLAGS) $<

clean : 
	rm -f *~ $(BIN) $(OBJ) $(SRCL) $(SRCY) $(OTHERS)

