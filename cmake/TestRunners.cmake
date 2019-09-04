# test environment (Python UI)
configure_file(bench/test_drivers/runner.py.in tmp/runner.py)
file(
    COPY ${CMAKE_BINARY_DIR}/tmp/runner.py
    DESTINATION ${CMAKE_BINARY_DIR}/tests
    FILE_PERMISSIONS
    OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)
set(TEST_RUNNER ${CMAKE_BINARY_DIR}/tests/runner.py)
set(DEBUGGER_TEST_RUNNER ${CMAKE_SOURCE_DIR}/tests/debugger/run.sh)

function(test_add name)

    set(options NIGHTLY DISABLE_SECURITY REVERT_RESULT)
    cmake_parse_arguments(PARSE_ARGV 1 TEST_DESCR "${options}" "" "")

    set(TEST_DIR "${CMAKE_BINARY_DIR}/tests/${name}")
    # This is a hack. Stupid cmake won't create working directories if not exist
    file(MAKE_DIRECTORY "${TEST_DIR}")

    if (${TEST_DESCR_DISABLE_SECURITY})
        set(AUX_CMD "--nonsecure-libc")
    else()
        set(AUX_CMD "")
    endif()

    add_test(NAME "${name}"
        COMMAND "${TEST_RUNNER}" ${TEST_DESCR_UNPARSED_ARGUMENTS} ${AUX_CMD}
             WORKING_DIRECTORY "${TEST_DIR}")

    if (${TEST_DESCR_NIGHTLY})
        set_tests_properties("${name}" PROPERTIES LABELS nightly)
    endif()

endfunction()

function(add_debugger_test name)
    set(TEST_DIR "${CMAKE_BINARY_DIR}/tests/${name}")
    # This is a hack. Stupid cmake won't create working directories if not exist
    file(MAKE_DIRECTORY "${TEST_DIR}")
    add_test(NAME "${name}"
        COMMAND ${DEBUGGER_TEST_RUNNER} ${TEST_RUNNER} ${ARGN}
             WORKING_DIRECTORY "${TEST_DIR}")
endfunction()

