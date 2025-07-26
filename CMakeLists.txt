cmake_minimum_required(VERSION 3.10)
project(HarmonyLinkProject LANGUAGES CXX)

# avoid CMP0111 warning
if(POLICY CMP0111)
    cmake_policy(SET CMP0111 NEW)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
endif()
message(STATUS "Configuring for ${CMAKE_BUILD_TYPE}")

# path to Cargo output
set(RUST_DIR "${CMAKE_SOURCE_DIR}/target")
string(TOLOWER "${CMAKE_BUILD_TYPE}" CFG)      # debug / release
string(TOUPPER "${CMAKE_BUILD_TYPE}" CFG_UPPER) # DEBUG / RELEASE

# helper to find artifact
function(find_art var kind)
  if(kind STREQUAL "static")
    set(ext a)
  else()
    set(ext so)
  endif()

  file(GLOB files
       "${RUST_DIR}/${CFG}/libharmony_link*.${ext}"
       "${RUST_DIR}/${CFG}/deps/libharmony_link*.${ext}")
  list(SORT files)
  list(GET files 0 f)
  if(NOT f)
    message(FATAL_ERROR "Missing Rust ${kind} lib in target/${CFG}")
  endif()
  set(${var} "${f}" PARENT_SCOPE)
endfunction()

find_art(RUST_STATIC static)
find_art(RUST_SHARED shared)

add_library(HarmonyLinkLibStatic STATIC IMPORTED GLOBAL)
set_target_properties(HarmonyLinkLibStatic PROPERTIES
  IMPORTED_LOCATION_${CFG_UPPER} "${RUST_STATIC}"
  INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_SOURCE_DIR}/include")

add_library(HarmonyLinkLibShared SHARED IMPORTED GLOBAL)
set_target_properties(HarmonyLinkLibShared PROPERTIES
  IMPORTED_LOCATION_${CFG_UPPER} "${RUST_SHARED}"
  INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_SOURCE_DIR}/include")

add_subdirectory(HarmonyLinkTest)
