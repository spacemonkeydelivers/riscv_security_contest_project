
set(ZEPHYR_APPS
    synchronization
    philosophers
    hello_world
    testing/integration
    portability/cmsis_rtos_v1/timer_synchronization
    portability/cmsis_rtos_v2/timer_synchronization
    ripe1
    ripe2
    ripe3
    ripe4
    ripe5
    # basic/threads # due too no SOURCES given to target: drivers__gpio
)

add_custom_target(
    Zephyr_apps ALL
)
foreach(TEST_NAME ${ZEPHYR_APPS})
    string(REPLACE "/" "_" APP_NAME ${TEST_NAME})
    set(TEST_PATH "samples/${TEST_NAME}")
    set(OUTPUT_PATH "${CMAKE_BINARY_DIR}/zephyr_build/${APP_NAME}")
    set(CROSS_ARG "${RISCV_TOOLCHAIN_PATH}/bin/riscv32-unknown-elf-")
    add_custom_command(
        OUTPUT ${OUTPUT_PATH}/zephyr/zephyr.elf
        COMMAND ${CMAKE_SOURCE_DIR}/cmake/helpers/zephyr_build.sh ${TEST_PATH} ${OUTPUT_PATH} ${CROSS_ARG}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/zephyrproject/zephyr
        VERBATIM
    )
    add_custom_target(app_${APP_NAME} DEPENDS ${OUTPUT_PATH}/zephyr/zephyr.elf)
    add_dependencies(Zephyr_apps app_${APP_NAME})
endforeach()

