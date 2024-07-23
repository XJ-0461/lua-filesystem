# filesystem tests

This directory contains tests for the filesystem module.

## Contents
1. /lib
    - Contains a simple library to assert and report test results.
2. /resources
    - Files and directories that the tests will act upon. Tests will be authored with this directory structure in mind.
3. /tests
    - Contains the tests for the filesystem module.

## Methodology

For ease of use, each of the tests, dependencies, and resources will be copied into the CMAKE_CURRENT_BINARY_DIR
(e.g. /<root>/linux-release-external-dependencies-lua-5_4/test/ when using --preset
linux-release-external-dependencies-lua-5_4). All dependencies bar the `/resources` folder will be flattened in the
directory.

The tests will operate on this copy of the `/resources` directory, which limits the potential for side effects when
testing multiple versions of the library at the same time, on the same machine.

Tests will be invoked with the target executable `lua-interpreter` known to CMake. When using a CMake preset that pulls
in and builds Lua automatically, this target will be imported for you with `find_package()` For example:
- preset `Linux Release Lua5.4` finds lua 5.4 executable at
    `/linux-release-external-dependencies-lua-5_4/cool-vcpkg/vcpkg_installed/cool-vcpkg-custom-triplet/tools/lua/lua`
- preset `Linux Release Lua5.3` finds lua 5.3 executable at
    `/linux-release-external-dependencies-lua-5_3/cool-vcpkg/vcpkg_installed/cool-vcpkg-custom-triplet/tools/lua/lua`

If you want to bring your own Lua, then the `lua-interpreter` target must be set manually setup.

## Running

The tests are driven by the CTest framework, a CMake module. They can be invoked by running `ctest` in the build
directory.

```shell
cd /path/to/build/linux-release-external-dependencies-lua-5_4
ctest
Test project /path/to/build/linux-release-external-dependencies-lua-5_4
      Start  1: path-tostring-test
 1/71 Test  #1: path-tostring-test ..........................................   Passed    0.00 sec
 ...
      Start 71: directory_iterator-recursive_directory_iterator-test
71/71 Test #71: directory_iterator-recursive_directory_iterator-test ........   Passed    0.00 sec

100% tests passed, 0 tests failed out of 71

Total Test time (real) =   0.13 sec
```

## Implementation Note

The `MakeTestSuite()` macro defined in CMakeLists is a helper to create a test suite from a test file. It
significantly cuts down the number of lines of code, and actually makes things look fairly nice. It generates
a CTest of the form `<filename>-<test_name>-test`. It assumes that you:

1. import the `test.lua` module
2. create a table of test cases in the test file mapping test_name (string) -> test_function (function).
