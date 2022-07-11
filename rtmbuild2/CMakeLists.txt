cmake_minimum_required(VERSION 3.0.2)
project(rtmbuild2)

find_package(catkin REQUIRED COMPONENTS )

find_package(PkgConfig)
pkg_check_modules(OMNIORB REQUIRED omniORB4)

catkin_package(
  DEPENDS OMNIORB
  CATKIN_DEPENDS message_generation std_msgs
  CFG_EXTRAS servicebridge2.cmake rtmbuild2.cmake
  )

install(DIRECTORY cmake scripts
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
  USE_SOURCE_PERMISSIONS
  )
