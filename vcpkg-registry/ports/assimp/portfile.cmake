vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO assimp/assimp
    REF v5.1.5
    SHA512 07e39de36340e5651c00f4b4363abd27dae5c3b5cdc4aba7a294e360a5724a3574975fb856e60c185f06d8510648ac3c0ed8d03ed03727ec3725f796c17aeafa
    HEAD_REF master
)

file(REMOVE ${SOURCE_PATH}/cmake-modules/FindZLIB.cmake)
file(REMOVE ${SOURCE_PATH}/cmake-modules/FindIrrXML.cmake)
#file(REMOVE_RECURSE ${SOURCE_PATH}/contrib/clipper) # https://github.com/assimp/assimp/issues/788
file(REMOVE_RECURSE ${SOURCE_PATH}/contrib/poly2tri)
file(REMOVE_RECURSE ${SOURCE_PATH}/contrib/zlib)
file(REMOVE_RECURSE ${SOURCE_PATH}/contrib/gtest)
file(REMOVE_RECURSE ${SOURCE_PATH}/contrib/irrXML)
file(REMOVE_RECURSE ${SOURCE_PATH}/contrib/rapidjson)
file(REMOVE_RECURSE ${SOURCE_PATH}/contrib/stb_image)
file(REMOVE_RECURSE ${SOURCE_PATH}/contrib/zip)
file(REMOVE_RECURSE ${SOURCE_PATH}/contrib/unzip)
file(REMOVE_RECURSE ${SOURCE_PATH}/contrib/utf8cpp)
#file(REMOVE_RECURSE ${SOURCE_PATH}/contrib/Open3DGC)      #TODO
#file(REMOVE_RECURSE ${SOURCE_PATH}/contrib/openddlparser) #TODO

set(VCPKG_C_FLAGS "${VCPKG_C_FLAGS} -D_CRT_SECURE_NO_WARNINGS")
set(VCPKG_CXX_FLAGS "${VCPKG_CXX_FLAGS} -D_CRT_SECURE_NO_WARNINGS")

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" ASSIMP_BUILD_SHARED_LIBS)
set (ASSIMP_VCPKG_IMPORTER_EXPORTER_FEATURES "")
foreach(feature ${FEATURES})
    string( FIND ${feature} "-importer" ASSIMP_VCPKG_FEATURE_TEST)
    if (NOT ${ASSIMP_VCPKG_FEATURE_TEST} EQUAL -1)
        string(SUBSTRING ${feature} 0 ${ASSIMP_VCPKG_FEATURE_TEST} ASSIMP_VCPKG_FEATURE_TEST)
        string(TOUPPER ${ASSIMP_VCPKG_FEATURE_TEST} ASSIMP_VCPKG_FEATURE_TEST)
        set (ASSIMP_VCPKG_FEATURE_TEST ASSIMP_BUILD_${ASSIMP_VCPKG_FEATURE_TEST}_IMPORTER)
        list (APPEND ASSIMP_VCPKG_IMPORTER_EXPORTER_FEATURES "-D${ASSIMP_VCPKG_FEATURE_TEST}=ON")
    endif()
    string( FIND ${feature} "-exporter" ASSIMP_VCPKG_FEATURE_TEST)
    if (NOT ${ASSIMP_VCPKG_FEATURE_TEST} EQUAL -1)
        string(SUBSTRING ${feature} 0 ${ASSIMP_VCPKG_FEATURE_TEST} ASSIMP_VCPKG_FEATURE_TEST)
        string(TOUPPER ${ASSIMP_VCPKG_FEATURE_TEST} ASSIMP_VCPKG_FEATURE_TEST)
        set (ASSIMP_VCPKG_FEATURE_TEST ASSIMP_BUILD_${ASSIMP_VCPKG_FEATURE_TEST}_EXPORTER)
        list (APPEND ASSIMP_VCPKG_IMPORTER_EXPORTER_FEATURES "-D${ASSIMP_VCPKG_FEATURE_TEST}=ON")
    endif()
endforeach()

message("${ASSIMP_VCPKG_IMPORTER_EXPORTER_FEATURES}")

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS -DASSIMP_BUILD_TESTS=OFF
            -DASSIMP_BUILD_ASSIMP_TOOLS=OFF
            -DASSIMP_BUILD_ZLIB=OFF
            -DBUILD_SHARED_LIBS=${ASSIMP_BUILD_SHARED_LIBS}
            -DASSIMP_INSTALL_PDB=OFF
            -DASSIMP_IGNORE_GIT_HASH=ON
            -DASSIMP_BUILD_ALL_EXPORTERS_BY_DEFAULT=OFF
            -DASSIMP_BUILD_ALL_IMPORTERS_BY_DEFAULT=OFF
            ${ASSIMP_VCPKG_IMPORTER_EXPORTER_FEATURES}
)

vcpkg_install_cmake()

# this is from the original port, have no idea what it is supposed to do
if(VCPKG_TARGET_IS_WINDOWS)
    set(VCVER vc140 vc141 vc142 )
    set(CRT mt md)
    set(DBG_NAMES)
    set(REL_NAMES)
    foreach(_ver IN LISTS VCVER)
        foreach(_crt IN LISTS CRT)
            list(APPEND DBG_NAMES assimp-${_ver}-${_crt}d)
            list(APPEND REL_NAMES assimp-${_ver}-${_crt})
        endforeach()
    endforeach()
endif()

find_library(ASSIMP_REL NAMES assimp ${REL_NAMES} PATHS "${CURRENT_PACKAGES_DIR}/lib" NO_DEFAULT_PATH)
find_library(ASSIMP_DBG NAMES assimp assimpd ${DBG_NAMES} PATHS "${CURRENT_PACKAGES_DIR}/debug/lib" NO_DEFAULT_PATH)
if(ASSIMP_REL)
    get_filename_component(ASSIMP_NAME_REL "${ASSIMP_REL}" NAME_WLE)
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/lib/pkgconfig/assimp.pc" "-lassimp" "-l${ASSIMP_NAME_REL}")
endif()
if(ASSIMP_DBG)
    get_filename_component(ASSIMP_NAME_DBG "${ASSIMP_DBG}" NAME_WLE)
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/assimp.pc" "-lassimp" "-l${ASSIMP_NAME_DBG}")
endif()

vcpkg_fixup_cmake_targets()
vcpkg_fixup_pkgconfig() # Probably requires more fixing for static builds. See qt5-3d and the config changes below
vcpkg_copy_pdbs()

file(READ ${CURRENT_PACKAGES_DIR}/share/assimp/assimpConfig.cmake ASSIMP_CONFIG)
file(WRITE ${CURRENT_PACKAGES_DIR}/share/assimp/assimpConfig.cmake "
include(CMakeFindDependencyMacro)
find_dependency(ZLIB)
find_dependency(irrlicht CONFIG)
find_dependency(polyclipping CONFIG)
find_dependency(minizip CONFIG)
find_dependency(kubazip CONFIG)
find_dependency(poly2tri CONFIG)
find_dependency(utf8cpp CONFIG)
${ASSIMP_CONFIG}")

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
