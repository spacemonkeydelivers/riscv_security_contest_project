project(ovp_models)
include(ExternalProject)

if (SUBPROJECT_INSTALL_PREFIX)
    set(_SUBPROJECT_INSTALL_PREFIX "${SUBPROJECT_INSTALL_PREFIX}")
else()
    set(_SUBPROJECT_INSTALL_PREFIX install)
endif()

set(IMPERAS_PATH "/tank/work/dev/Imperas.20190628" CACHE PATH "A path to Imperas installation" FORCE)

if (NOT EXISTS ${IMPERAS_PATH})
    message("No Imperas installation found, setup IMPERAS_PATH with a command line")
else()
    message("Found Imperas in ${IMPERAS_PATH}")
endif()

ExternalProject_Add(
    ovp_models
    PREFIX ${SUBPROJECT_INSTALL_PREFIX}

    TMP_DIR "${CMAKE_BINARY_DIR}/tmp/"
    STAMP_DIR "${CMAKE_BINARY_DIR}/tmp/"
    BINARY_DIR "${CMAKE_BINARY_DIR}/tmp/"
    DOWNLOAD_DIR "${CMAKE_BINARY_DIR}/tmp/"

    CONFIGURE_COMMAND "" 
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
    BUILD_ALWAYS True
    BUILD_COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/buildutils/builder build ${IMPERAS_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/source ${MODELS_FILES_ROOT}/ovp
    INSTALL_COMMAND ""
)

set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${MODELS_FILES_ROOT}/ovp")
