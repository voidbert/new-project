# %LICENSE_HEADER%
# CONFIGURATION VARIABLES

CC              := gcc
CFLAGS          := -Wall -Wextra -Werror -pedantic
STANDARDS       := -std=c99 -D_POSIX_C_SOURCE=200809L
LIBS            := -lm -lpthread

DEBUG_CFLAGS    := -O0 -ggdb
RELEASE_CFLAGS  := -O2

# Note: none of these directories can be the root of the project
# Also, these may need to be updated in .gitignore
BUILDDIR        := build
EXENAME         := %PROJECT_NAME%
DEPDIR          := deps
DOCSDIR         := docs
OBJDIR          := obj

# END OF CONFIGURATION

SOURCES = $(shell find "src" -name '*.c' -type f)
HEADERS = $(shell find "include" -name '*.h' -type f)
OBJECTS = $(patsubst src/%.c, $(OBJDIR)/%.o, $(SOURCES))
DEPENDS = $(patsubst src/%.c, $(DEPDIR)/%.d, $(SOURCES))

ifeq ($(DEBUG), 1)
	CFLAGS += $(DEBUG_CFLAGS)
else
	CFLAGS += $(RELEASE_CFLAGS)
endif
CFLAGS += $(STANDARDS)

default: $(BUILDDIR)/$(EXENAME)

# Welcome to my unorthodox Makefile! To get auto-dependency generation working, this code is
# unusual for a Makefile, but hey, it works!
#
# To compile a source file, a makefile rule is generated with $(CC) -MM, to account for header
# dependencies. The commands that actually compile the source are added to that rule file before
# its included.
$(DEPDIR)/%.d: src/%.c Makefile
	$(eval OBJ := $(patsubst src/%.c, $(OBJDIR)/%.o, $<))

	@# Commands to make the object's file directory, compile the source and re-generate the file
	@# dependencies to $@2 while compiling. The dependencies are modifed (format), to put them in
	@# a single line and to add the dependency file to the rule's outputs.
	@#
	@# An echo command is used to give feedback on GCC (instead of make's output), to remove the
	@# preprocessor options related to dependency generation.

	$(eval RULE_CMD_MKDIR = @mkdir -p $(shell dirname $(OBJ)))
	$(eval RULE_CMD_FEEDBACK = @echo $(CC) -c -o $(OBJ) $< $(CFLAGS) -Iinclude)
	$(eval RULE_CMD_GCC = @$(CC) -MMD -MT $(OBJ) -MF $@2 -MP -c -o $(OBJ) $< $(CFLAGS) -Iinclude)
	$(eval RULE_CMD_FORMAT = @sed -ze 's/ \\\\\\\\\\\\n//g ; s|$(OBJ):|$(OBJ) $@:|g' -i $@2)

	@# Create another temporary dependency file ($@3), to update the dependencies, but keeping
	@# the compiler commands form $@. Then, $@3 is copied into $@ and the temporary files are
	@# removed.
	$(eval RULE_CMD_ADD_COMMANDS = @head -n1 $@2 > $@3 ; \
	                                tail -n+2 $@ | grep '^\\s' >> $@3 ; \
	                                tail -n+2 $@2 >> $@3)
	$(eval RULE_CMD_COPY = @cp $@3 $@ ; rm $@2 $@3)

	@# Create the dependency file for the first time, adding all the commands.
	@mkdir -p $(shell dirname $@)
	$(CC) -MM $< -MT $(OBJ) -Iinclude > $@

	@printf "\t$(RULE_CMD_MKDIR)\n" >> $@
	@printf "\t$(RULE_CMD_FEEDBACK)\n" >> $@
	@printf "\t$(RULE_CMD_GCC)\n" >> $@
	@printf "\t$(RULE_CMD_FORMAT)\n" >> $@
	@printf "\t$(RULE_CMD_ADD_COMMANDS)\n" >> $@
	@printf "\t$(RULE_CMD_COPY)\n" >> $@

# Only generate dependencies for tasks that require them
ifeq (, $(filter clean, $(MAKECMDGOALS)))
include $(DEPENDS)
endif

$(BUILDDIR)/$(EXENAME): $(OBJECTS)
	@mkdir -p $(BUILDDIR)
	$(CC) -o $@ $^ $(LIBS)

define Doxyfile
	INPUT                  = include src README.md
	RECURSIVE              = YES
	EXTRACT_ALL            = YES
	FILE_PATTERNS          = *.h *.c

	PROJECT_NAME           = %PROJECT_NAME%
	USE_MDFILE_AS_MAINPAGE = README.md

	OUTPUT_DIRECTORY       = $(DOCSDIR)
	GENERATE_HTML          = YES
	GENERATE_LATEX         = NO
endef
export Doxyfile

$(DOCSDIR): $(SOURCES) $(HEADERS)
	echo "$$Doxyfile" | doxygen -

.PHONY: clean
clean:
	rm -r $(BUILDDIR) $(DEPDIR) $(DOCSDIR) $(OBJDIR) 2> /dev/null ; true
