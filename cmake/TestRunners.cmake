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

    set(options_no_value
        NIGHTLY
        DISABLE_SECURITY
        INVERT_RESULT
        WARN_DISABLE
        SPIKE_FAILURE
        ENABLE_C_EXT)

    set(options_one_value
        TICKS_TIMEOUT)

    cmake_parse_arguments(PARSE_ARGV 1 TEST_DESCR "${options_no_value}" "${options_one_value}" "")

    set(TEST_DIR "${CMAKE_BINARY_DIR}/tests/${name}")
    set(TEST_DIR_SIM "${CMAKE_BINARY_DIR}/tests/sim_${name}")
    # This is a hack. Stupid cmake won't create working directories if not exist
    file(MAKE_DIRECTORY "${TEST_DIR}")
    file(MAKE_DIRECTORY "${TEST_DIR_SIM}")

    if (${TEST_DESCR_INVERT_RESULT})
        set(RINVERT "--driver-invert-result")
    endif()

    if (${TEST_DESCR_DISABLE_SECURITY})
        set(NSC "--nonsecure-libc")
    endif()

    if (${TEST_DESCR_WARN_DISABLE})
        set(NOWARN "--disable-c-warnings")
    endif()

    if (${TEST_DESCR_ENABLE_C_EXT})
        set(ENABLE_C "--enable-compressed")
    endif()

    if (${TEST_DESCR_TICKS_TIMEOUT})
        set(TEST_TICKS_TIMEOUT "--ticks-timeout=${TEST_DESCR_TICKS_TIMEOUT}")
    endif()

    add_test(NAME "${name}"
        COMMAND "${TEST_RUNNER}" ${TEST_DESCR_UNPARSED_ARGUMENTS}
                ${RINVERT} ${NSC} ${NOWARN} ${ENABLE_C} ${TEST_TICKS_TIMEOUT}
        WORKING_DIRECTORY "${TEST_DIR}")

    add_test(NAME "sim_${name}"
        COMMAND "${TEST_RUNNER}" ${TEST_DESCR_UNPARSED_ARGUMENTS}
                ${RINVERT} ${NSC} ${NOWARN} ${ENABLE_C} ${TEST_TICKS_TIMEOUT}
                --spike
                WORKING_DIRECTORY "${TEST_DIR_SIM}")

    if (${TEST_DESCR_NIGHTLY})
        set_tests_properties("${name}" PROPERTIES LABELS nightly)
        set_tests_properties("sim_${name}" PROPERTIES LABELS nightly)
    endif()

    if (${TEST_DESCR_SPIKE_FAILURE})
        set_tests_properties("sim_${name}" PROPERTIES LABELS "nightly;sim_failure")
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

