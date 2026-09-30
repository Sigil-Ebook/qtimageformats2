cmake_minimum_required(VERSION 3.16)
project(qavif VERSION 1.0 LANGUAGES C CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

find_package(Qt6 REQUIRED COMPONENTS Gui)

qt_standard_project_setup()

qt_add_library(qavif
    src/main.cpp
    src/qavifhandler.cpp src/qavifhandler_p.h
    src/util_p.h
)

target_link_directories(qavif PRIVATE "${CMAKE_BINARY_DIR}/lib")
    
target_link_libraries(qavif PRIVATE
    Qt::Core
    Qt::Gui
    avif
    yuv::yuv
    aom
)
