cmake_minimum_required(VERSION 3.0.2)
project(rtmbuild_sample0)

# rtmbuild has non exist dependency
# (ROSBUILD_genmsg_cpp) and (RTMBUILD_${PROJECT_NAME}_genidl)
cmake_policy(SET CMP0046 OLD)

find_package(catkin REQUIRED COMPONENTS
  rtmbuild2
  roscpp)

rtmbuild2_init()

catkin_package(
#  INCLUDE_DIRS include
  LIBRARIES RtmBuildSample0ServiceStub RtmBuildSample0ServiceSkel RtmBuildSample0StructStub RtmBuildSample0StructSkel
#  CATKIN_DEPENDS other_catkin_pkg
#  DEPENDS system_lib
)

rtmbuild2_genidl()

rtmbuild2_genbridge()
