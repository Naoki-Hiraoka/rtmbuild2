cmake_minimum_required(VERSION 3.0.2)
project(rtmbuild2)

find_package(catkin REQUIRED COMPONENTS
  std_msgs
  message_generation)

find_package(PkgConfig)
pkg_check_modules(OMNIORB REQUIRED omniORB4)

include(cmake/rtmbuild2.cmake)
include(cmake/servicebridge2.cmake)
rtmbuild2_init()
rtmbuild2_genidl()

catkin_package(
  LIBRARIES ${${PROJECT_NAME}_IDLLIBRARY_DIRS}
  DEPENDS OMNIORB
  CATKIN_DEPENDS message_generation std_msgs
  CFG_EXTRAS servicebridge2.cmake rtmbuild2.cmake
  )

install(DIRECTORY cmake scripts
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
  USE_SOURCE_PERMISSIONS
  )
