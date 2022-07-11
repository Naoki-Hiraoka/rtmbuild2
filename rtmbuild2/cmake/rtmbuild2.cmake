cmake_minimum_required(VERSION 2.8.3)

#set(DEBUG_RTMBUILD2_CMAKE TRUE)

##
## GLOBAL VARIABLES
##
## openrtm_aist_INCLUDE_DIRS
## openrtm_aist_LIBRARIES
## openhrp3_INCLUDE_DIRS
## openhrp3_LIBRARIES
## idl2srv_EXECUTABLE
## rtmskel_EXECUTABLE
## ${PROJECT_NAME}_idl_files
## ${PROJECT_NAME}_autogen_files
## ${PROJECT_NAME}_autogen_msg_files
## ${PROJECT_NAME}_autogen_srv_files
## ${PROJECT_NAME}_autogen_interfaces
## rtm_idlc, rtm_idlflags, rtm_idldir
## rtm_cxx,  rtm_cflags
## hrp_idldir


#
# setup global variables
#
macro(rtmbuild2_init)
  set(_extra_message_dependencies ${ARGV0})
  #
  # use pkg-config to set --cflags --libs plus rtm-related flags
  #
  find_package(PkgConfig)
  pkg_check_modules(openrtm_aist openrtm-aist REQUIRED)
  pkg_check_modules(openhrp3 openhrp3.1)
  message("[rtmbuild2_init] Building package ${CMAKE_SOURCE_DIR} ${PROJECT_NAME}")
  message("[rtmbuild2_init] - CATKIN_TOPLEVEL = ${CATKIN_TOPLEVEL}")
  if(DEBUG_RTMBUILD2_CMAKE)
    message("[rtmbuild2_init] - openrtm_aist_INCLUDE_DIRS -> ${openrtm_aist_INCLUDE_DIRS}")
    message("[rtmbuild2_init] - openrtm_aist_LIBRARIES    -> ${openrtm_aist_LIBRARIES}")
    message("[rtmbuild2_init] - openhrp3_INCLUDE_DIRS -> ${openhrp3_INCLUDE_DIRS}")
    message("[rtmbuild2_init] - openhrp3_LIBRARIES    -> ${openhrp3_LIBRARIES}")
  endif()

  if(EXISTS ${rtmbuild2_SOURCE_PREFIX}) # catkin
    set(idl2srv_EXECUTABLE ${rtmbuild2_SOURCE_PREFIX}/scripts/idl2srv.py)
  else()
    pkg_check_modules(rtmbuild rtmbuild REQUIRED)
    set(idl2srv_EXECUTABLE ${rtmbuild2_PREFIX}/share/rtmbuild/scripts/idl2srv.py)
  endif()
  # on melodic (18.04) omnniorb requries python3
  if($ENV{ROS_DISTRO} STRGREATER "lunar")
    set(idl2srv_EXECUTABLE "python3;${idl2srv_EXECUTABLE}")
  endif()
  message("[rtmbuild2_init] - idl2srv_EXECUTABLE     -> ${idl2srv_EXECUTABLE}")

  execute_process(COMMAND pkg-config openrtm-aist --variable=prefix      OUTPUT_VARIABLE rtm_prefix    OUTPUT_STRIP_TRAILING_WHITESPACE)
  if(EXISTS ${rtm_prefix}/bin/rtm-skelwrapper)
    set(_rtm_exe_path ${rtm_prefix}/bin)
  else()
    set(_rtm_exe_path ${rtm_prefix}/lib/openrtm_aist/bin)
  endif()
  set(rtmskel_EXECUTABLE PATH=${_rtm_exe_path}:$ENV{PATH} PYTHONPATH=${openrtm_aist_PREFIX}/lib/openrtm-1.1/py_helper:$ENV{PYTHONPATH} ${_rtm_exe_path}/rtm-skelwrapper)
  message("[rtmbuild2_init] - rtmskel_EXECUTABLE     -> ${rtmskel_EXECUTABLE}")

  execute_process(COMMAND pkg-config openrtm-aist --variable=rtm_idlc     OUTPUT_VARIABLE rtm_idlc     OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND pkg-config openrtm-aist --variable=rtm_idlflags OUTPUT_VARIABLE rtm_idlflags OUTPUT_STRIP_TRAILING_WHITESPACE)
  set(rtm_idlflags "${rtm_idlflags} -Wbuse_quotes -Wbkeep_inc_path") # IDLs in hrpsys-base needs this option because of https://github.com/start-jsk/rtmros_common/issues/861. We can remove this after openrtm-aist.pc is updated.
  execute_process(COMMAND pkg-config openrtm-aist --variable=rtm_idldir   OUTPUT_VARIABLE rtm_idldir   OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND pkg-config openrtm-aist --variable=rtm_cxx      OUTPUT_VARIABLE rtm_cxx      OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND pkg-config openrtm-aist --variable=rtm_cflags   OUTPUT_VARIABLE rtm_cflags   OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND pkg-config openrtm-aist --variable=rtm_libs     OUTPUT_VARIABLE rtm_libs     OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND pkg-config openhrp3.1   --variable=idl_dir      OUTPUT_VARIABLE hrp_idldir   OUTPUT_STRIP_TRAILING_WHITESPACE)
  separate_arguments(rtm_idlflags)
  separate_arguments(rtm_cflags)
  separate_arguments(rtm_libs)
  set(rtm_cxx "c++") ## openrtm-aist --variable=rtm_cxx sometimes returns /usr/lib/ccache/c++
  set(extra_idlflags "")
  foreach(_extra_message_dependency ${_extra_message_dependencies})
    foreach(_extra_idldir ${${_extra_message_dependency}_INCLUDE_DIRS})
      list(APPEND extra_idlflags -I${_extra_idldir})
    endforeach()
  endforeach()
  message("[rtmbuild2_init] - rtm_idlc               -> ${rtm_idlc}")
  message("[rtmbuild2_init] - rtm_idlflags           -> ${rtm_idlflags}")
  message("[rtmbuild2_init] - rtm_idldir             -> ${rtm_idldir}")
  message("[rtmbuild2_init] - rtm_cxx                -> ${rtm_cxx}")
  message("[rtmbuild2_init] - rtm_cflags             -> ${rtm_cflags}")
  message("[rtmbuild2_init] - rtm_libs               -> ${rtm_libs}")
  message("[rtmbuild2_init] - hrp_idldir             -> ${hrp_idldir}")
  message("[rtmbuild2_init] - extra_message_dependencies -> ${_extra_message_dependencies}")
  message("[rtmbuild2_init] - extra_idlflags         -> ${extra_idlflags}")

  ##
  ## get idl files and store to _idl_list
  message("[rtmbuild2_init] Generating bridge compornents from ${PROJECT_SOURCE_DIR}/idl")
  set(${PROJECT_NAME}_idl_files "")
  _rtmbuild2_get_idls() ## set ${PROJECT_NAME}_idl_files
  message("[rtmbuild2_init] - ${PROJECT_NAME}_idl_files : ${${PROJECT_NAME}_idl_files}")
  if(NOT ${PROJECT_NAME}_idl_files)
    message(AUTHOR_WARNING "[rtmbuild2_init] - no idl file is defined")
  endif()

  ## generate msg/srv/cpp from idl
  set(${PROJECT_NAME}_autogen_msg_files "")
  set(${PROJECT_NAME}_autogen_srv_files "")
  _rtmbuild2_genbridge_init(${_extra_message_dependencies})
  message("[rtmbuild2_init] - ${PROJECT_NAME}_autogen_msg_files  : ${${PROJECT_NAME}_autogen_msg_files}")
  message("[rtmbuild2_init] - ${PROJECT_NAME}_autogen_srv_files  : ${${PROJECT_NAME}_autogen_srv_files}")
  message("[rtmbuild2_init] - ${PROJECT_NAME}_autogen_interfaces : ${${PROJECT_NAME}_autogen_interfaces}")
  set(rtmbuild2_${PROJECT_NAME}_autogen_msg_files ${${PROJECT_NAME}_autogen_msg_files}) 


  add_message_files(DIRECTORY msg FILES "${${PROJECT_NAME}_autogen_msg_files}")
  add_service_files(DIRECTORY srv FILES "${${PROJECT_NAME}_autogen_srv_files}")
  generate_messages(DEPENDENCIES std_msgs ${_extra_message_dependencies})

  # since catkin > 0.7.0, the CPATH is no longer being set by catkin, so rtmbuild manually add them
  set(_cmake_prefix_path_tmp $ENV{CMAKE_PREFIX_PATH})
  string(REPLACE ":" ";" _cmake_prefix_path_tmp ${_cmake_prefix_path_tmp})
  foreach(_cmake_prefix_path ${_cmake_prefix_path_tmp})
    include_directories(${_cmake_prefix_path}/include)
    link_directories(${_cmake_prefix_path}/lib)
  endforeach()

  include_directories(${openhrp3_INCLUDE_DIRS} ${openrtm_aist_INCLUDE_DIRS} ${catkin_INCLUDE_DIRS})
  link_directories(${openhrp3_LIBRARY_DIRS} ${openrtm_aist_LIBRARY_DIRS} ${catkin_LIBRARY_DIRS})

endmacro(rtmbuild2_init)

# add_custom_command to compile idl/*.idl file into c++
macro(rtmbuild2_genidl)
  message("[rtmbuild2_genidl] add_custom_command for idl files in package ${PROJECT_NAME}")

  set(_autogen "")

  set(_output_cpp_dir ${CATKIN_DEVEL_PREFIX}/${CATKIN_PACKAGE_INCLUDE_DESTINATION})
  set(_output_lib_dir ${CATKIN_DEVEL_PREFIX}/${CATKIN_PACKAGE_LIB_DESTINATION})
  set(_output_python_dir ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_PYTHON_DESTINATION}/${PROJECT_NAME})

  set(_output_idl_py_files "")
  set(_output_idl_hh_files "")
  file(MAKE_DIRECTORY ${_output_cpp_dir}/idl)
  file(MAKE_DIRECTORY ${_output_lib_dir})
  link_directories(${_output_lib_dir})

  message("[rtmbuild2_genidl] - _output_cpp_dir : ${_output_cpp_dir}")
  message("[rtmbuild2_genidl] - _output_lib_dir : ${_output_lib_dir}")
  message("[rtmbuild2_genidl] - _output_python_dir : ${_output_python_dir}")

  ## RTMBUILD2_${PROJECT_NAME}_genrpc) depends on each RTMBUILD2_${PROJECT_NAME}_${_idl_name}_genrpc)
  add_custom_target(RTMBUILD2_${PROJECT_NAME}_genrpc)
  if(NOT ${PROJECT_NAME}_idl_files)
    message(AUTHOR_WARNING "[rtmbuild2_genidl] - no idl file is defined")
  endif()
  foreach(_idl_file ${${PROJECT_NAME}_idl_files})
    get_filename_component(_idl_name ${_idl_file} NAME_WE)
    message("[rtmbuild2_genidl] - _idl_file : ${_idl_file}")
    message("[rtmbuild2_genidl] - _idl_name : ${_idl_name}")

    # set(_input_idl ${PROJECT_SOURCE_DIR}/idl/${_idl})

    set(_output_idl_hh ${_output_cpp_dir}/idl/${_idl_name}.hh)
    set(_output_idl_py ${_output_python_dir}/${_idl_name}_idl.py)
    set(_output_stub_h ${_output_cpp_dir}/idl/${_idl_name}Stub.h)
    set(_output_skel_h ${_output_cpp_dir}/idl/${_idl_name}Skel.h)
    set(_output_stub_cpp ${_output_cpp_dir}/idl/${_idl_name}Stub.cpp)
    set(_output_skel_cpp ${_output_cpp_dir}/idl/${_idl_name}Skel.cpp)
    set(_output_stub_lib ${_output_lib_dir}/lib${_idl_name}Stub.so)
    set(_output_skel_lib ${_output_lib_dir}/lib${_idl_name}Skel.so)
    list(APPEND ${PROJECT_NAME}_IDLLIBRARY_DIRS lib${_idl_name}Stub.so lib${_idl_name}Skel.so)
    # call the  rule to compile idl
    if(DEBUG_RTMBUILD2_CMAKE)
      message("[rtmbuild2_genidl] ${_output_idl_hh}\n -> ${_idl_file} ${${_idl}_depends}")
      message("[rtmbuild2_genidl] ${_output_stub_cpp} ${_output_skel_cpp} ${_output_stub_h} ${_output_skel_h}\n -> ${_output_idl_hh}")
      message("[rtmbuild2_genidl] ${_output_stub_lib} ${_output_skel_lib}\n -> ${_output_stub_cpp} ${_output_stub_h} ${_output_skel_cpp} ${_output_skel_h}")
    endif()
    # cpp
    add_custom_command(OUTPUT ${_output_idl_hh}
      COMMAND ${rtm_idlc} ${extra_idlflags} ${rtm_idlflags} -C${_output_cpp_dir}/idl ${_idl_file}
      DEPENDS ${_idl_file})
    add_custom_command(OUTPUT ${_output_stub_cpp} ${_output_skel_cpp} ${_output_stub_h} ${_output_skel_h}
      COMMAND cp ${_idl_file} ${_output_cpp_dir}/idl
      COMMAND rm -f ${_output_stub_cpp} ${_output_skel_cpp} ${_output_stub_h} ${_output_skel_h}
      COMMAND ${rtmskel_EXECUTABLE} --include-dir="" --skel-suffix=Skel --stub-suffix=Stub  --idl-file=${_idl_file}
      WORKING_DIRECTORY ${_output_cpp_dir}/idl
      DEPENDS ${_output_idl_hh})
    add_custom_command(OUTPUT ${_output_stub_lib} ${_output_skel_lib}
      COMMAND ${rtm_cxx} ${extra_idlflags} ${rtm_cflags} -I. -shared -o ${_output_stub_lib} ${_output_stub_cpp} ${rtm_libs}
      COMMAND ${rtm_cxx} ${extra_idlflags} ${rtm_cflags} -I. -shared -o ${_output_skel_lib} ${_output_skel_cpp} ${rtm_libs}
      DEPENDS ${_output_stub_cpp} ${_output_stub_h} ${_output_skel_cpp} ${_output_skel_h})
    list(APPEND ${PROJECT_NAME}_IDLLIBRARY_DIRS ${_output_stub_lib} ${_output_skel_lib})
    if(use_catkin)
      install(PROGRAMS ${_output_stub_lib} ${_output_skel_lib} DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION})
    endif()
    # python
    list(APPEND _output_idl_py_files ${_output_idl_py})
    # cpp
    list(APPEND _output_idl_hh_files ${_output_idl_hh})
    #
    list(APPEND _autogen ${_output_stub_lib} ${_output_skel_lib} ${_output_idl_py})

    # add custom target
    add_custom_target(RTMBUILD2_${PROJECT_NAME}_${_idl_name}_genrpc DEPENDS ${_output_stub_lib} ${_output_skel_lib})
    add_dependencies(RTMBUILD2_${PROJECT_NAME}_genrpc RTMBUILD2_${PROJECT_NAME}_${_idl_name}_genrpc)
    # genrpc may depends on any idl (generate all .hh filesbefore compiling rpc https://github.com/fkanehiro/hrpsys-base/pull/886)
    add_dependencies(RTMBUILD2_${PROJECT_NAME}_${_idl_name}_genrpc RTMBUILD2_${PROJECT_NAME}_genhh)

  endforeach(_idl_file)
  # python
  add_custom_target(RTMBUILD2_${PROJECT_NAME}_genpy DEPENDS ${_output_idl_py_files})
  add_custom_command(OUTPUT ${_output_idl_py_files}
    COMMAND mkdir -p ${_output_python_dir}
    COMMAND echo \"${rtm_idlc} -bpython ${extra_idlflags} -I${rtm_idldir} -C${_output_python_dir} ${${PROJECT_NAME}_idl_files}\"
    COMMAND ${rtm_idlc} -bpython ${extra_idlflags} -I${rtm_idldir} -C${_output_python_dir} ${${PROJECT_NAME}_idl_files}
    COMMENT "Generating python/idl from ${${PROJECT_NAME}_idl_files}"
    DEPENDS ${${PROJECT_NAME}_idl_files})
  add_dependencies(RTMBUILD2_${PROJECT_NAME}_genrpc RTMBUILD2_${PROJECT_NAME}_genpy)
  # cpp (generate all .hh filesbefore compiling rpc https://github.com/fkanehiro/hrpsys-base/pull/886)
  add_custom_target(RTMBUILD2_${PROJECT_NAME}_genhh DEPENDS ${_output_idl_hh_files})
  add_dependencies(RTMBUILD2_${PROJECT_NAME}_genrpc RTMBUILD2_${PROJECT_NAME}_genhh)
  ##

  if(_autogen)
    if(DEBUG_RTMBUILD2_CMAKE)
      message("[rtmbuild2_genidl] ADDITIONAL_MAKE_CLEAN_FILES : ${_autogen}")
    endif()
    # Also set up to clean the srv_gen directory
    get_directory_property(_old_clean_files ADDITIONAL_MAKE_CLEAN_FILES)
    list(APPEND _old_clean_files ${_autogen})
    set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${_old_clean_files}")
  endif(_autogen)
endmacro(rtmbuild2_genidl)

macro(rtmbuild2_genbridge)
  message("[rtmbuild2_genbridge] generate OpenRTM-ROS bridges")
  #
  add_custom_target(RTMBUILD2_${PROJECT_NAME}_genbridge)

  message("[rtmbuild2_genbridge] - ${PROJECT_NAME}_autogen_interfaces : ${${PROJECT_NAME}_autogen_interfaces}")
  if(NOT ${PROJECT_NAME}_autogen_interfaces)
    message(AUTHOR_WARNING "[rtmbuild2_genbridge] - no interface is defined")
  endif()
  foreach(_comp ${${PROJECT_NAME}_autogen_interfaces})
    message("[rtmbuild2_genbridge] - rtmbuild2_add_executable : ${_comp}ROSBridgeComp")
    rtmbuild2_add_executable("${_comp}ROSBridgeComp" "src_gen/${_comp}ROSBridge.cpp" "src_gen/${_comp}ROSBridgeComp.cpp")
    add_custom_target(RTMBUILD2_${PROJECT_NAME}_${_comp}_genbridge DEPENDS src_gen/${_comp}ROSBridge.cpp src_gen/${_comp}ROSBridgeComp.cpp)
    add_dependencies(RTMBUILD2_${PROJECT_NAME}_genbridge RTMBUILD2_${PROJECT_NAME}_${_comp}_genbridge)
  endforeach(_comp)

  # TARGET
  ## RTMBUILD2_${PROJECT_NAME}_gencpp    : generated cpp files from idl with id2srv.py
  ##                                    -> depends on idl
  ## RTMBUILD2_${PROJECT_NAME}_genrpc    : stub/skel files generated from genidl
  ##                                    -> RTMBUILD2_${PROJECT_NAME}_gencpp
  ## RTMBUILD2_${PROJECT_NAME}_genbridge : bridge component files generated from stub skel
  ##                                    -> RTMBUILD2_${PROJECT_NAME}_genrpc
  ## ${exe}                             -> RTMBUILD2_${PROJECT_NAME}_genbridge

  add_dependencies(RTMBUILD2_${PROJECT_NAME}_gencpp ${PROJECT_NAME}_generate_messages_cpp ${PROJECT_NAME}_generate_messages_py)
  add_dependencies(RTMBUILD2_${PROJECT_NAME}_genrpc RTMBUILD2_${PROJECT_NAME}_gencpp)
  add_dependencies(RTMBUILD2_${PROJECT_NAME}_genbridge RTMBUILD2_${PROJECT_NAME}_genrpc)

endmacro(rtmbuild2_genbridge)

macro(rtmbuild2_add_executable exe)
  add_executable(${ARGV})
  install(TARGETS ${exe} RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION})
  ## disable -Wdeprecated to shorten the log data
  ## ^~~~~
  ## /opt/ros/melodic/include/openrtm-1.1/rtm/PeriodicExecutionContext.h:633:7: warning: dynamic exception specifications are deprecated in C++11 [-Wdeprecated]
  ## throw (CORBA::SystemException);
  ## ^~~~~
  ## The job exceeded the maximum log length, and has been terminated.
  set_target_properties(${exe} PROPERTIES COMPILE_FLAGS "-Wno-deprecated")
  ##
  add_dependencies(${exe} RTMBUILD2_${PROJECT_NAME}_genbridge ${${_package}_EXPORTED_TARGETS} ${catkin_EXPORTED_TARGETS} )
  target_link_libraries(${exe} ${openhrp3_LIBRARIES} ${${PROJECT_NAME}_IDLLIBRARY_DIRS} ${openrtm_aist_LIBRARIES} ${catkin_LIBRARIES}  )
endmacro(rtmbuild2_add_executable)

macro(rtmbuild2_add_library lib)
  add_library(${ARGV})
  install(TARGETS ${LIB} LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION})
  target_link_libraries(${lib}  ${openhrp3_LIBRARIES} ${openrtm_aist_LIBRARIES} ${${PROJECT_NAME}_IDLLIBRARY_DIRS})
endmacro(rtmbuild2_add_library)

