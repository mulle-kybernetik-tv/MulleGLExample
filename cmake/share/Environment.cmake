if( NOT __ENVIRONMENT__CMAKE__)
   set( __ENVIRONMENT__CMAKE__ ON)

   if( MULLE_TRACE_INCLUDE)
      message( STATUS "# Include \"${CMAKE_CURRENT_LIST_FILE}\"" )
   endif()

   #
   #
   #
   set( MULLE_VIRTUAL_ROOT "$ENV{MULLE_VIRTUAL_ROOT}")
   if( NOT MULLE_VIRTUAL_ROOT)
      set( MULLE_VIRTUAL_ROOT "${PROJECT_SOURCE_DIR}")
   endif()

   # get MULLE_SDK_PATH into cmake list form
   # MULLE_SDK_PATH is set my mulle-craft and usually looks like the
   # default set below. But! If you are using --sdk --platform
   # distictions the paths will be different
   #
   string( REPLACE ":" ";" MULLE_SDK_PATH "$ENV{MULLE_SDK_PATH}")

   if( NOT MULLE_SDK_PATH)
      set( MULLE_SDK_PATH
         "${MULLE_VIRTUAL_ROOT}/dependency"
         "${MULLE_VIRTUAL_ROOT}/addiction"
      )
   endif()

   set( TMP_INCLUDE_DIRS)

   ###
   ### If you build DEBUG buildorder, but want RELEASE interspersed, so that
   ### the debugger doesn't trace through too much fluff then set the
   ### FALLBACK_BUILD_TYPE (for lack of a better name)
   ###
   ### TODO: reenable later
   ###
   # if( NOT FALLBACK_BUILD_TYPE)
   #    set( FALLBACK_BUILD_TYPE "$ENV{MULLE_GL_EXAMPLE_FALLBACK_BUILD_TYPE}")
   #    if( NOT FALLBACK_BUILD_TYPE)
   #       set( FALLBACK_BUILD_TYPE "$ENV{FALLBACK_BUILD_TYPE}")
   #    endif()
   #    if( NOT FALLBACK_BUILD_TYPE)
   #       set( FALLBACK_BUILD_TYPE "Debug")
   #    endif()
   # endif()
#
   # if( FALLBACK_BUILD_TYPE STREQUAL "Release")
   #    unset( FALLBACK_BUILD_TYPE)
   # endif()

   foreach( TMP_SDK_PATH in ${MULLE_SDK_PATH})
      #
      # Add build-type includes/libs first
      # Add Release as a fallback afterwards
      #
      # The CMAKE_INCLUDE_PATH path for the CMAKE_BUILD_TYPE are added
      # unconditionally just in case ppl do interesting stuff in their
      # CMakeLists
      #
      # We always prepend to "override" inherited values, so
      # the order seems reversed
      #
      if( EXISTS "${TMP_SDK_PATH}")
         set( TMP_SDK_RELEASE_PATH "${TMP_SDK_PATH}/Release")
         if( NOT EXISTS "${TMP_SDK_RELEASE_PATH}")
            set( TMP_SDK_RELEASE_PATH "${TMP_SDK_PATH}")
         endif()

         if( CMAKE_BUILD_TYPE STREQUAL "Release" OR EXISTS "${TMP_SDK_RELEASE_PATH}/include")
            set( CMAKE_INCLUDE_PATH
               "${TMP_SDK_RELEASE_PATH}/include"
               ${CMAKE_INCLUDE_PATH}
            )
            set( TMP_INCLUDE_DIRS
               "${TMP_SDK_RELEASE_PATH}/include"
               ${TMP_INCLUDE_DIRS}
            )
         endif()

         if( CMAKE_BUILD_TYPE STREQUAL "Release" OR EXISTS "${TMP_SDK_RELEASE_PATH}/lib")
            set( CMAKE_LIBRARY_PATH
               "${TMP_SDK_RELEASE_PATH}/lib"
               ${CMAKE_LIBRARY_PATH}
            )
         endif()
         if( CMAKE_BUILD_TYPE STREQUAL "Release" OR EXISTS "${TMP_SDK_RELEASE_PATH}/Frameworks")
            set( CMAKE_FRAMEWORK_PATH
               "${TMP_SDK_RELEASE_PATH}/Frameworks"
               ${CMAKE_FRAMEWORK_PATH}
            )
         endif()

         unset( TMP_SDK_RELEASE_PATH)

         #
         # now add build type unconditionally
         #
         if( NOT CMAKE_BUILD_TYPE STREQUAL "Release")
            set( CMAKE_INCLUDE_PATH
               "${TMP_SDK_PATH}/${CMAKE_BUILD_TYPE}/include"
               ${CMAKE_INCLUDE_PATH}
            )
            set( TMP_INCLUDE_DIRS
               "${TMP_SDK_PATH}/${CMAKE_BUILD_TYPE}/include"
               ${TMP_INCLUDE_DIRS}
            )

            set( CMAKE_LIBRARY_PATH
               "${TMP_SDK_PATH}/${CMAKE_BUILD_TYPE}/lib"
               ${CMAKE_LIBRARY_PATH}
            )
            set( CMAKE_FRAMEWORK_PATH
               "${TMP_SDK_PATH}/${CMAKE_BUILD_TYPE}/Frameworks"
               ${CMAKE_FRAMEWORK_PATH}
            )
         endif()
      endif()
   endforeach()

   message( STATUS "CMAKE_INCLUDE_PATH=\"${CMAKE_INCLUDE_PATH}\"" )
   message( STATUS "CMAKE_LIBRARY_PATH=\"${CMAKE_LIBRARY_PATH}\"" )
   message( STATUS "CMAKE_FRAMEWORK_PATH=\"${CMAKE_FRAMEWORK_PATH}\"" )
   message( STATUS "INCLUDE_DIRS=\"${TMP_INCLUDE_DIRS}\"" )


   include_directories( BEFORE SYSTEM
      ${TMP_INCLUDE_DIRS}
   )

   unset( TMP_INCLUDE_DIRS)

   #
   #
   # include files that get installed
   set( CMAKE_INCLUDES
      "cmake/DependenciesAndLibraries.cmake"
      "cmake/_Dependencies.cmake"
      "cmake/_Libraries.cmake"
   )

   # IDE visible cmake files
   set( CMAKE_EDITABLE_FILES
      CMakeLists.txt
      cmake/Headers.cmake
      cmake/Sources.cmake
      cmake/DependenciesAndLibraries.cmake
   )

   #
   # Parallel build support. run all "participating" projects once for
   # HEADERS_PHASE in parallel.
   # Now run all "participating" projects for COMPILE_PHASE in parallel.
   # Finally run all participating and non-participating projects in buildorder
   # serially together with the LINK_PHASE. What is tricky is that the
   # sequential projects may need to run first.
   #
   option( HEADERS_PHASE  "Install headers only phase (1)" OFF)
   option( COMPILE_PHASE  "Compile sources only phase (2)" OFF)
   option( LINK_PHASE     "Link and install only phase (3)" OFF)

   if( MULLE_MAKE_PHASE STREQUAL "HEADERS")
      set( HEADERS_PHASE ON)
   endif()
   if( MULLE_MAKE_PHASE STREQUAL "COMPILE")
      set( COMPILE_PHASE ON)
   endif()
   if( MULLE_MAKE_PHASE STREQUAL "LINK")
      set( LINK_PHASE ON)
   endif()

   if( NOT HEADERS_PHASE AND
       NOT COMPILE_PHASE AND
       NOT LINK_PHASE)
      set( HEADERS_PHASE ON)
      set( COMPILE_PHASE ON)
      set( LINK_PHASE ON)
   endif()

   #
   # https://stackoverflow.com/questions/32469953/why-is-cmake-designed-so-that-it-removes-runtime-path-when-installing/32470070#32470070
   # MULLE_NO_CMAKE_INSTALL_RPATH can be used to kill this codepath
   #
   if( NOT MULLE_NO_CMAKE_INSTALL_RPATH)
      if( APPLE)
         set( CMAKE_INSTALL_RPATH "@rpath/../lib")
      else()
         set( CMAKE_INSTALL_RPATH "\$ORIGIN/../lib")
      endif()
   endif()

   include( EnvironmentAux OPTIONAL)

endif()
