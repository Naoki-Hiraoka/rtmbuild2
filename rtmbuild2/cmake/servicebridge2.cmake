# belows are private macros ..
macro(_rtmbuild2_get_idls)
  file(GLOB _idl_files "${PROJECT_SOURCE_DIR}/idl/*.idl")  ## get full path
  foreach(_idl_file ${_idl_files})
    # copy from rosbuild_get_msgs to avoid .#Foo.idl, by emacs
    if(${_idl_file} MATCHES "/[^\\.]+\\.idl$")
      list(APPEND ${PROJECT_NAME}_idl_files ${_idl_file})
    endif()
  endforeach(_idl_file)
endmacro(_rtmbuild2_get_idls)


# generate msg/srv files from idl, this will be called in rtmbuild2_init
macro(_rtmbuild2_genbridge_init)
  set(_extra_message_dependencies ${ARGV})

  set(extra_idl_dirs "")
  set(extra_package_paths "")
  foreach(_extra_message_dependency ${_extra_message_dependencies})
    foreach(_extra_idldir ${${_extra_message_dependency}_INCLUDE_DIRS})
      set(extra_idl_dirs "${extra_idl_dirs} ${_extra_idldir}")
    endforeach()
    if(EXISTS ${${_extra_message_dependency}_SOURCE_PREFIX})
      set(extra_package_paths "${extra_package_paths} ${${_extra_message_dependency}_SOURCE_PREFIX}")
    elseif(EXISTS ${${_extra_message_dependency}_PREFIX}/share/${_extra_message_dependency})
      set(extra_package_paths "${extra_package_paths} ${${_extra_message_dependency}_PREFIX}/share/${_extra_message_dependency}")
    else()
      message(ERROR "${_extra_message_dependency} not found")
    endif()
  endforeach()
  if(DEBUG_RTMBUILD2_CMAKE)
    message("[_rtmbuild2_genbridge_init] - extra_idl_dirs      -> ${extra_idl_dirs}")
    message("[_rtmbuild2_genbridge_init] - extra_package_paths -> ${extra_package_paths}")
  endif()

  set(_autogen "")

  string(RANDOM _rand_str)
  list(APPEND _autogen ${PROJECT_SOURCE_DIR}/src_gen)

  ## RTMBUILD2_${PROJECT_NAME}_gencpp) depends on each RTMBUILD2_${PROJECT_NAME}_${_idl_name}_gencpp)
  add_custom_target(RTMBUILD2_${PROJECT_NAME}_gencpp)
  set(idl_dirs "${rtm_idldir}")
  if(EXISTS "${hrp_idldir}")
    set(idl_dirs "${idl_dirs} ${hrp_idldir}")
  endif()
  set(idl_dirs "${idl_dirs} ${extra_idl_dirs}")

  foreach(_idl_file ${${PROJECT_NAME}_idl_files})
    get_filename_component(_idl_name ${_idl_file} NAME_WE)
    ##
    ## gen cpp/msg/srv filenames from idl and store filename to _autogen_files
    if(DEBUG_RTMBUILD2_CMAKE)
      message("[_rtmbuild2_genbridge_init] Get msgs/srvs filenames from ${_idl_file}")
      message("[_rtmbuild2_genbridge_init] running\n>> ${idl2srv_EXECUTABLE} -i ${_idl_file} --include-dirs=\"${idl_dirs}\" --package-name=${PROJECT_NAME} --tmpdir=/tmp/idl2srv_${PROJECT_NAME}_${_idl_name}_${_rand_str} --include-msgsrv-package-paths=\"${extra_package_paths}\"")
    endif()
    ##
    set(${PROJECT_NAME}_autogen_files "")
    execute_process(COMMAND ${idl2srv_EXECUTABLE} -i ${_idl_file} --include-dirs="${idl_dirs}" --package-name=${PROJECT_NAME} --tmpdir=/tmp/idl2srv_${PROJECT_NAME}_${_idl_name}_${_rand_str} --include-msgsrv-package-paths="${extra_package_paths}" OUTPUT_VARIABLE ${PROJECT_NAME}_autogen_files OUTPUT_STRIP_TRAILING_WHITESPACE RESULT_VARIABLE _idl2srv_failed ERROR_VARIABLE _idl2srv_error)
    if(DEBUG_RTMBUILD2_CMAKE)
      message("[_rtmbuild2_genbridge_init] ${idl2srv_EXECUTABLE} returned ${_idl2srv_failed} (stdout:${${PROJECT_NAME}_autogen_files}, stderr:${_idl2srv_error})")
      message("[_rtmbuild2_genbridge_init] ${PROJECT_NAME}_autogen_files : ${${PROJECT_NAME}_autogen_files}")
    endif()
    if ( _idl2srv_failed )
      message(WARNING ".. running idl2srv.py failed ${_idl2srv_error} ${_autogen_files}")
      message(WARNING ">> ${idl2srv_EXECUTABLE} -i ${_idl_file} --include-dirs=\"${idl_dirs}\" --package-name=${PROJECT_NAME} --tmpdir=/tmp/idl2srv_${PROJECT_NAME}_${_idl_name}_${_rand_str}")
      message(FATAL_ERROR "quitting...")
    endif()

    if ( ${PROJECT_NAME}_autogen_files )

      string(REPLACE "\n" ";" ${PROJECT_NAME}_autogen_files  ${${PROJECT_NAME}_autogen_files})
      ##
      ## set _autogen_msg_files, _autogen_srv_files
      if(DEBUG_RTMBUILD2_CMAKE)
        message("[_rtmbuild2_genbridge_init] ${PROJECT_NAME}_autogen_files : ${${PROJECT_NAME}_autogen_files}")
      endif()

      ## setup _autogen_msg_files, _autogen_srv_files
      set(${PROJECT_NAME}_${_idl_name}_autogen_interfaces "")
      set(${PROJECT_NAME}_${_idl_name}_autogen_msg_file  "")
      set(${PROJECT_NAME}_${_idl_name}_autogen_srv_file  "")
      set(${PROJECT_NAME}_${_idl_name}_autogen_cpp_file  "")
      foreach(_autogen_file ${${PROJECT_NAME}_autogen_files})
        if(DEBUG_RTMBUILD2_CMAKE)
          message("[_rtmbuild2_genbridge_init] _autogen_file : ${_autogen_file}")
        endif()
        get_filename_component(_ext ${_autogen_file} EXT)
        get_filename_component(_nam ${_autogen_file} NAME)
        if(NOT _ext)
          list(APPEND ${PROJECT_NAME}_${_idl_name}_autogen_interfaces ${_nam})
        elseif(${_ext} STREQUAL ".msg" )
          list(APPEND ${PROJECT_NAME}_${_idl_name}_autogen_msg_files ${_nam})
        elseif(${_ext} STREQUAL ".srv" )
          list(APPEND ${PROJECT_NAME}_${_idl_name}_autogen_srv_files ${_nam})
        elseif(${_ext} STREQUAL ".cpp" OR ${_ext} STREQUAL ".h" )
          list(APPEND ${PROJECT_NAME}_${_idl_name}_autogen_cpp_files ${_autogen_file})
        endif()
        list(FIND _autogen ${_autogen_file} _found_autogen_file)
        if(${_found_autogen_file} GREATER -1)
          list(REMOVE_ITEM ${PROJECT_NAME}_autogen_files ${_autogen_file})
          message("[_rtmbuild2_genbridge_init] remove already generated file ${_autogen_file}")
        endif(${_found_autogen_file} GREATER -1)
      endforeach(_autogen_file)
      if(DEBUG_RTMBUILD2_CMAKE)
        message("[_rtmbuild2_genbridge_init] ${PROJECT_NAME}_${_idl_name}_autogen_msg_files : ${${PROJECT_NAME}_${_idl_name}_autogen_msg_files}")
        message("[_rtmbuild2_genbridge_init] ${PROJECT_NAME}_${_idl_name}_autogen_srv_files : ${${PROJECT_NAME}_${_idl_name}_autogen_srv_files}")
        message("[_rtmbuild2_genbridge_init] ${PROJECT_NAME}_${_idl_name}_autogen_cpp_files : ${${PROJECT_NAME}_${_idl_name}_autogen_cpp_files}")
      endif()
      list(APPEND ${PROJECT_NAME}_autogen_msg_files  ${${PROJECT_NAME}_${_idl_name}_autogen_msg_files})
      list(APPEND ${PROJECT_NAME}_autogen_srv_files  ${${PROJECT_NAME}_${_idl_name}_autogen_srv_files})
      list(APPEND ${PROJECT_NAME}_autogen_interfaces ${${PROJECT_NAME}_${_idl_name}_autogen_interfaces})

      # add custom command for nexttime you invoke make
      if( ${PROJECT_NAME}_${_idl_name}_autogen_cpp_files )
        separate_arguments(tmp_idl_dirs UNIX_COMMAND "${idl_dirs}") # We need to use separate_arguments fot add_custom_target's arguments
        separate_arguments(tmp_extra_package_paths UNIX_COMMAND "${extra_package_paths}") # We need to use separate_arguments fot add_custom_target's arguments
        add_custom_command(OUTPUT ${${PROJECT_NAME}_${_idl_name}_autogen_cpp_files}
          COMMAND ${idl2srv_EXECUTABLE} -i ${_idl_file} --include-dirs="${tmp_idl_dirs}" --package-name=${PROJECT_NAME} --tmpdir=/tmp/idl2srv_${PROJECT_NAME}_${_idl_name}_${_rand_str} --include-msgsrv-package-paths="${tmp_extra_package_paths}"
          DEPENDS ${_idl_file})
      endif()

      list(APPEND _autogen /tmp/idl2srv_${PROJECT_NAME}_${_idl_name}_${_rand_str})

    endif( ${PROJECT_NAME}_autogen_files ) 

    # add custom target
    add_custom_target(RTMBUILD2_${PROJECT_NAME}_${_idl_name}_gencpp DEPENDS ${${PROJECT_NAME}_${_idl_name}_autogen_cpp_files})
    add_dependencies(RTMBUILD2_${PROJECT_NAME}_gencpp RTMBUILD2_${PROJECT_NAME}_${_idl_name}_gencpp)

  endforeach(_idl_file)

  if(DEBUG_RTMBUILD2_CMAKE)
    message("[_rtmbuild2_genbridge_init] ${PROJECT_NAME}_autogen_msg_files : ${${PROJECT_NAME}_autogen_msg_files}")
    message("[_rtmbuild2_genbridge_init] ${PROJECT_NAME}_autogen_srv_files : ${${PROJECT_NAME}_autogen_srv_files}")
  endif()

  if(_autogen)
    if(DEBUG_RTMBUILD2_CMAKE)
      message("[_rtmbuild2_genbridge_init] ADDITIONAL_MAKE_CLEAN_FILES : ${_autogen}")
    endif()
    # setup clean files from generated msg/srv/cpp/h files
    get_directory_property(_old_clean_files ADDITIONAL_MAKE_CLEAN_FILES)
    list(APPEND _old_clean_files ${_autogen})
    set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${_old_clean_files}")
  endif(_autogen)

endmacro(_rtmbuild2_genbridge_init)
