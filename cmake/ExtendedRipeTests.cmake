set(ERIPE_DIR "${CMAKE_BINARY_DIR}/extended_ripe")
file(MAKE_DIRECTORY "${ERIPE_DIR}")

execute_process(
    COMMAND ${CMAKE_SOURCE_DIR}/proto/test_cfg_generator.py
        --cfg-dir=${ERIPE_DIR}/cfg_ns --name-prefix=fullripe_nS_
        --src=c/ripe --disable-security
        --output=${ERIPE_DIR}/NonSecureTests.txt
    OUTPUT_FILE ${ERIPE_DIR}/gen_log_ns.log
    WORKING_DIRECTORY "${ERIPE_DIR}")

execute_process(
    COMMAND ${CMAKE_SOURCE_DIR}/proto/test_cfg_generator.py
        --cfg-dir=${ERIPE_DIR}/cfg_s --name-prefix=fullripe_secure_
        --src=c/ripe --invert-result
        --output=${ERIPE_DIR}/SecureTests.txt
    OUTPUT_FILE ${ERIPE_DIR}/gen_log_s.log
    WORKING_DIRECTORY "${ERIPE_DIR}")

include(${ERIPE_DIR}/NonSecureTests.txt)
include(${ERIPE_DIR}/SecureTests.txt)

