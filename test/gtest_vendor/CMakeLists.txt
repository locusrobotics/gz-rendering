# Prefer an installed GoogleTest (e.g. Homebrew's) when one exists. Its
# headers live in a shared prefix such as /opt/homebrew/include that other
# dependencies add to the include path, so building the vendored sources
# would compile tests against one gtest version and link them to another.
find_package(GTest CONFIG QUIET GLOBAL)
if(GTest_FOUND)
  add_library(gtest INTERFACE)
  target_link_libraries(gtest INTERFACE GTest::gtest)
  add_library(gtest_main INTERFACE)
  target_link_libraries(gtest_main INTERFACE GTest::gtest_main)
  return()
endif()

add_library(gtest STATIC ${CMAKE_CURRENT_SOURCE_DIR}/src/gtest-all.cc)
add_library(gtest_main STATIC ${CMAKE_CURRENT_SOURCE_DIR}/src/gtest_main.cc)

target_include_directories(gtest 
  SYSTEM PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/src
)
target_link_libraries(gtest_main gtest)
