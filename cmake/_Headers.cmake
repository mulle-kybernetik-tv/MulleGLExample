#
# cmake/_Headers.cmake is generated by `mulle-sde`. Edits will be lost.
#
if( MULLE_TRACE_INCLUDE)
   MESSAGE( STATUS "# Include \"${CMAKE_CURRENT_LIST_FILE}\"" )
endif()

set( INCLUDE_DIRS
nanosvg/src
nanovg/src
src
) 

set( PRIVATE_HEADERS
src/import-private.h
src/include-private.h
)

set( PUBLIC_HEADERS
nanosvg/src/nanosvg.h
nanosvg/src/nanosvgrast.h
nanovg/src/fontstash.h
nanovg/src/nanovg_gl.h
nanovg/src/nanovg_gl_utils.h
nanovg/src/nanovg.h
nanovg/src/stb_image.h
nanovg/src/stb_truetype.h
src/CALayer.h
src/CGBase.h
src/CGGeometry.h
src/MulleSVGImage.h
src/MulleSVGLayer.h
src/import.h
src/include.h
src/tiger-svg.inc
src/version.h
) 

