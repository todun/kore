#!/bin/sh
#
# Copyright (c) 2013 Joris Vink <joris@coders.se>
#
# Kore module build script, use this as a base for building
# your own modules for kore.

# The name of the module you will be building
MODULE=example.module

# The directory containing all your media files (HTML, CSS, ...).
# These files will be compiled into the module and symbols will
# be exported for you to use in your code.
MEDIA_DIR=media

# The directory containing your module source.
SOURCE_DIR=src

# The directory containing the Kore source code.
KORE_DIR=../../

# Compiler settings.
CC=gcc
CFLAGS="-I. -I${KORE_DIR}/includes -Wall -Wstrict-prototypes \
	-Wmissing-prototypes -Wmissing-declarations -Wshadow \
	-Wpointer-arith -Wcast-qual -Wsign-compare -g"

OSNAME=$(uname -s | sed -e 's/[-_].*//g' | tr A-Z a-z)
if [ "${OSNAME}" = "darwin" ]; then
	LDFLAGS="-dynamiclib -undefined suppress -flat_namespace"
else
	LDFLAGS="-shared"
fi

MODULE_BUILD_DATE=$(date +"%Y-%m-%d %H:%M:%S")

### Begin building ####
echo "Building module ${MODULE}..."
rm -f ${MODULE}

${CC} ${CFLAGS} tools/inject.c -o tools/inject

if [ ! -d ${SOURCE_DIR}/${MEDIA_DIR} ]; then
	mkdir ${SOURCE_DIR}/${MEDIA_DIR};
fi
rm -f ${SOURCE_DIR}/${MEDIA_DIR}/*

if [ ! -d .objs ]; then
	mkdir .objs;
fi
rm -f .objs/*

rm -f static.h

for file in `find ${MEDIA_DIR} -type f \( ! -name \*.swp \)`; do
	echo "Injecting $file";
	base=`basename $file`;
	./tools/inject $file $base > ${SOURCE_DIR}/${MEDIA_DIR}/${base}.c;
	if [ $? -ne 0 ]; then
		echo "Injection error, check above messages for clues.";
		exit 1;
	fi
done

echo "#define MODULE_BUILD_DATE \"${MODULE_BUILD_DATE}\"" >> static.h

for src in `find ${SOURCE_DIR} -type f -name \*.c`; do
	base=`basename $src`;
	${CC} ${CFLAGS} -fPIC -c $src -o .objs/${base}.o
	if [ $? -ne 0 ]; then
		echo "Build error, check above messages for clues.";
		exit 1;
	fi
done

${CC} ${LDFLAGS} `find .objs -name \*.o -type f` -o ${MODULE}
echo "Building completed!"

rm -rf ${SOURCE_DIR}/${MEDIA_DIR}
rm -rf .objs
rm -f tools/inject
rm -f static.h
