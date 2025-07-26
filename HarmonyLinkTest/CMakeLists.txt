# HarmonyLinkTest/CMakeLists.txt

# gather test sources
file(GLOB_RECURSE TEST_SOURCES "src/*.cpp")

# static‐linked test
add_executable(HarmonyLinkTestStatic ${TEST_SOURCES})
target_compile_definitions(HarmonyLinkTestStatic PRIVATE HARMONYLINKLIB_STATIC)
target_link_libraries(HarmonyLinkTestStatic PRIVATE HarmonyLinkLibStatic)

# shared‐linked test
add_executable(HarmonyLinkTestShared ${TEST_SOURCES})
target_compile_definitions(HarmonyLinkTestShared PRIVATE HARMONYLINKLIB_SHARED)
target_link_libraries(HarmonyLinkTestShared PRIVATE HarmonyLinkLibShared)

# copy shared lib next to exe
add_custom_command(TARGET HarmonyLinkTestShared POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "$<TARGET_FILE:HarmonyLinkLibShared>"
    "$<TARGET_FILE_DIR:HarmonyLinkTestShared>"
)
