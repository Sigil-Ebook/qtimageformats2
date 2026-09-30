cmake_minimum_required(VERSION 3.16)
project(qjpegxl6 VERSION 1.0 LANGUAGES C CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

find_package(Qt6 REQUIRED COMPONENTS Gui)

qt_standard_project_setup()

qt_add_plugin(qjpegxl6)
target_sources(qjpegxl6 PRIVATE
    src/main.cpp
    src/qjpegxlhandler.cpp src/qjpegxlhandler_p.h
    src/util_p.h
)

target_link_directories(qjpegxl6 PRIVATE
    "${CMAKE_BINARY_DIR}/lib"
)

target_link_libraries(qjpegxl6 PRIVATE
    Qt::Core
    Qt::Gui
    brotlicommon
    brotlidec
    brotlienc
    hwy
    jxl
    jxl_cms
    jxl_threads
)

install(TARGETS qjpegxl6
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    FRAMEWORK DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
