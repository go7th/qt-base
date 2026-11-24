cmake_minimum_required(VERSION 3.16)
project(test1 VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick VirtualKeyboard SerialPort Sql Concurrent Network)
qt_standard_project_setup()

qt_add_executable(apptest1
    src/main.cpp
    src/interface/apiclient.h   src/interface/apiclient.cpp
    src/interface/dbbridge.h    src/interface/dbbridge.cpp
    src/interface/redisclient.h src/interface/redisclient.cpp
    src/interface/serialbridge.h src/interface/serialbridge.cpp
    src/model/taskworker.h      src/model/taskworker.cpp
)

# QML 单例必须在 qt_add_qml_module 之前声明
set_source_files_properties(qml/config/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set_source_files_properties(qml/config/AppConfig.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(apptest1
    URI test1
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/config/Theme.qml
        qml/config/AppConfig.qml
        qml/components/ProjectCard.qml
        qml/pages/LoginPage.qml
        qml/pages/SerialPage.qml
        qml/pages/ProjectListPage.qml
        qml/pages/ProjectDetailPage.qml
        qml/pages/ApiPage.qml
        qml/pages/ThreadPage.qml
        qml/pages/DatabasePage.qml
        qml/pages/RedisPage.qml
        qml/pages/VectorPage.qml
)

target_include_directories(apptest1 PRIVATE src)

target_link_libraries(apptest1 PRIVATE
    Qt6::Quick
    Qt6::VirtualKeyboard
    Qt6::SerialPort
    Qt6::Sql
    Qt6::Concurrent
    Qt6::Network
)
