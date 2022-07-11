cmake_minimum_required(VERSION 3.0.2)
project(rtmbuild_sample1)

find_package(catkin REQUIRED COMPONENTS
  rtmbuild2
  roscpp
  rtmbuild_sample0
  )

rtmbuild2_init(rtmbuild_sample0 rtmbuild2)

rtmbuild2_genidl()

catkin_package(
#  INCLUDE_DIRS include
  LIBRARIES ${${PROJECT_NAME}_IDLLIBRARY_DIRS}
#  CATKIN_DEPENDS other_catkin_pkg
#  DEPENDS system_lib
)


rtmbuild2_genbridge()

add_executable(talker src/talker.cpp)
target_link_libraries(talker ${catkin_LIBRARIES})

