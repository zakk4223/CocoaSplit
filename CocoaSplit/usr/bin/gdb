#! /bin/sh

host_arch=""
requested_arch="UNSET"
architecture_to_use=""

PATH=$PATH:/sbin:/bin:/usr/sbin:/usr/bin

# gdb is setgid procmod and dyld will truncate any DYLD_FRAMEWORK_PATH etc
# settings on exec.  The user is really trying to set these things
# in their process, not gdb.  So we smuggle it over the setgid border in
# GDB_DYLD_* where it'll be laundered inside gdb before invoking the inferior.

unset GDB_DYLD_FRAMEWORK_PATH
unset GDB_DYLD_FALLBACK_FRAMEWORK_PATH
unset GDB_DYLD_LIBRARY_PATH
unset GDB_DYLD_FALLBACK_LIBRARY_PATH
unset GDB_DYLD_ROOT_PATH
unset GDB_DYLD_PATHS_ROOT
unset GDB_DYLD_IMAGE_SUFFIX
unset GDB_DYLD_INSERT_LIBRARIES
[ -n "$DYLD_FRAMEWORK_PATH" ] && GDB_DYLD_FRAMEWORK_PATH="$DYLD_FRAMEWORK_PATH"
[ -n "$DYLD_FALLBACK_FRAMEWORK_PATH" ] && GDB_DYLD_FALLBACK_FRAMEWORK_PATH="$DYLD_FALLBACK_FRAMEWORK_PATH"
[ -n "$DYLD_LIBRARY_PATH" ] && GDB_DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH"
[ -n "$DYLD_FALLBACK_LIBRARY_PATH" ] && GDB_DYLD_FALLBACK_LIBRARY_PATH="$DYLD_FALLBACK_LIBRARY_PATH"
[ -n "$DYLD_ROOT_PATH" ] && GDB_DYLD_ROOT_PATH="$DYLD_ROOT_PATH"
[ -n "$DYLD_PATHS_ROOT" ] && GDB_DYLD_PATHS_ROOT="$DYLD_PATHS_ROOT"
[ -n "$DYLD_IMAGE_SUFFIX" ] && GDB_DYLD_IMAGE_SUFFIX="$DYLD_IMAGE_SUFFIX"
[ -n "$DYLD_INSERT_LIBRARIES" ] && GDB_DYLD_INSERT_LIBRARIES="$DYLD_INSERT_LIBRARIES"
export GDB_DYLD_FRAMEWORK_PATH
export GDB_DYLD_FALLBACK_FRAMEWORK_PATH
export GDB_DYLD_LIBRARY_PATH
export GDB_DYLD_FALLBACK_LIBRARY_PATH
export GDB_DYLD_ROOT_PATH
export GDB_DYLD_PATHS_ROOT
export GDB_DYLD_IMAGE_SUFFIX
export GDB_DYLD_INSERT_LIBRARIES

# dyld will warn if any of these are set and the user invokes a setgid program
# like gdb.
unset DYLD_FRAMEWORK_PATH
unset DYLD_FALLBACK_FRAMEWORK_PATH
unset DYLD_LIBRARY_PATH
unset DYLD_FALLBACK_LIBRARY_PATH
unset DYLD_ROOT_PATH
unset DYLD_PATHS_ROOT
unset DYLD_IMAGE_SUFFIX
unset DYLD_INSERT_LIBRARIES

host_arch=`/usr/bin/arch 2>/dev/null` || host_arch=""

if [ "$host_arch" == "arm" ]
then
  host_arch=armv7            # default to armv7
  host_cpusubtype=`sysctl hw.cpusubtype | awk '{ print $NF }'` || host_cputype=""
  case "$host_cpusubtype" in
    6) host_arch="armv6" ;;
    7) host_arch="armv5" ;;
    9) host_arch="armv7" ;;
    10) host_arch="armv7f" ;;
    11) host_arch="armv7s" ;;
    12) host_arch="armv7k" ;;
    *) echo warning: unrecognized host cpusubtype ${host_cpusubtype}, defaulting to host==armv7. >&2 ;;
  esac
elif [ -z "$host_arch" ]
then
    echo "There was an error executing 'arch(1)'; assuming 'i386'.";
    host_arch="i386";
fi

# Not sure if this helps anything in particular - gdb should pick the
# x86_64 arch by default when available and the hardware supports it.
# And it might cause issues with some of our older branches so I'll
# leave it commented out for the moment.
#
#if [ $host_arch = i386 ]
#then
#  x86_64_p=`sysctl -n hw.optional.x86_64 2>/dev/null`
#  if [ -n "$x86_64_p" -a "$x86_64_p" = "1" ]
#  then
#    host_arch=x86_64
#  fi
#fi

case "$1" in
 --help)
    echo "  -arch x86_64|arm|armv6|armv7||armv7f|armv7s|i386         Specify a gdb targetting a specific architecture" >&2
    ;;
  -arch=* | -a=* | --arch=*)
    requested_arch=`echo "$1" | sed 's,^[^=]*=,,'`
    shift;;
  -arch | -a | --arch)
    shift
    requested_arch="$1"
    shift;;
esac

if [ -z "$requested_arch" ]
then
  echo ERROR: No architecture specified with -arch argument. >&2
  exit 1
fi
[ "$requested_arch" = "UNSET" ] && requested_arch=""

if [ -n "$requested_arch" ]
then
  case $requested_arch in
    i386 | x86_64 | arm*)
     ;;
    *)
      echo Unrecognized architecture \'$requested_arch\', using host arch. >&2
      requested_arch=""
      ;;
  esac
fi


# Determine if we're debugging a core file or an
# executable file.

# Then get the list of architectures contained in
# that executable/core file.

exec_file=
core_file=
file_archs=

for arg in "$@"
do
  case "$arg" in
    -*)
      # Skip all option arguments
      ;;
    *)
      # Call file to determine the file type of the argument
      [ ! -f "$arg" ] && continue
      file_result=`file "$arg"`
      case "$file_result" in
        *\ Mach-O\ core\ *|*\ Mach-O\ 64-bit\ core\ *)
          core_file=$arg
          ;;
        *\ Mach-O\ *)
          exec_file=$arg
          ;;
        *)
          if [ -x "$arg" ]
          then
            exec_file="$arg"
          fi
          ;;
      esac
      ;;
  esac
done
if [ -n "$core_file" ]
then
  core_file_tmp=`file "$core_file" 2>/dev/null | tail -1`
fi
if [ -n "$core_file" -a -n "$core_file_tmp" ]
then
  # file(1) has a weird way of identifying x86_64 core files; they have
  # a magic of MH_MAGIC_64 but a cputype of CPU_TYPE_I386.  Probably a bug.
  if echo "$core_file_tmp" | grep 'Mach-O 64-bit core i386' >/dev/null
  then
    file_archs=x86_64
  else
    file_archs=`echo "$core_file_tmp" | awk '{print $NF}'`
  fi
else
  if [ -n "$exec_file" ]
  then
    file_archs=`file "$exec_file" | grep -v universal | awk '{ print $NF }'`
    # file(1) says "arm" instead of specifying WHICH arm architecture - 
    # lipo -info can provide specifics.
    if echo "$file_archs" | grep 'arm' >/dev/null
    then
      if lipo -info "$exec_file" | egrep "^Architectures in the fat file|^Non-fat file" >/dev/null
      then
        lipo_archs=`lipo -info "$exec_file" | 
                    sed -e 's,^Archi.* are: ,,' -e 's,^Non-fat.*ture: ,,' | 
                    sed 's,(cputype (12) cpusubtype (11)),armv7s,' |
                    sed 's,cputype 12 cpusubtype 11,armv7s,' |
                    tr  ' ' '\n' | grep arm`
        file_archs="$file_archs $lipo_archs"
        file_archs=`echo $file_archs | tr ' ' '\n' | sort | uniq | grep -v '^arm$'`
      fi
    fi
  fi
fi

if [ -n "$requested_arch" ]
then
  architecture_to_use="$requested_arch"

# arm is a tricky one because file(1) still reports "arm" for files but
# you really need to specify armv6 or armv7 or whatever.  So if the user
# invoked us with '-arch arm' and there is only one arm fork present in
# the file, replace the user's arch spec with the correct one.

  if [ $requested_arch = arm ]
  then
    file_arm_archs=`echo $file_archs | tr ' ' '\n' |grep arm`
    if [ -n "$file_arm_archs" ]
    then
      arm_arch_count=`echo "$file_arm_archs" | wc -w`
      if [ "$arm_arch_count" -eq 1 ]
      then
        architecture_to_use=$file_arm_archs
        requested_arch=$file_arm_archs
      fi
    fi
  fi
else
  # No architecture was specified. We will try to find the executable
  # or a core file in the list of arguments, and launch the correct
  # gdb for the job. If there are multiple architectures in the executable,
  # we will search for the architecture that matches the host architecture.
  # If all this searching doesn't produce a match, we will use a gdb that
  # matches the host architecture by default.
  best_arch=
  # Iterate through the architectures and try and find the best match.
  for file_arch in $file_archs 
  do
    # If we don't have any best architecture set yet, use this in case
    # none of them match the host architecture.
    if [ -z "$best_arch" ]
    then
      best_arch="$file_arch"
      continue
    fi

    # See if the file architecture matches the host, and if so set the
    # best architecture to that.
    if [ "$file_arch" = "$host_arch" ]
    then
      best_arch="$file_arch"
      continue
    fi

    # If this is an armv7s or armv7f system, the armv7 slice is
    # the next-best arch to pick if we don't have an exact match.
    if [ "$host_arch" = armv7f -o "$host_arch" = armv7s ]
    then
      if [ "$file_arch" = armv7 ]
      then
        best_arch=$file_arch
        continue
      fi
    fi

    # if this is an armv7k system, the armv6 slice is the 
    # next-best arch to pick if we don't have an exact match.
    if [ "$host_arch" = armv7k -a "$file_arch" = armv6 ]
    then
      best_arch="$file_arch"
      continue
    fi

    # in the absence of any better information, if we have
    # an armv6 slice and an armv7 slice, and we don't have
    # a counter-indication from the host_arch, pick the armv7.
    if [ "$best_arch" = armv6 -a "$file_arch" = armv7 ]
    then
      if [ "$host_arch" != armv6 -a "$host_arch" != armv7k ]
      then
        best_arch="$file_arch"
        continue
      fi
    fi

  done

  case "$best_arch" in
    i386 | x86_64 | arm*)
      # We found a plausible architecture and we will use it
      architecture_to_use="$best_arch"
      ;;
    *)
      # We did not find a plausible architecture, use the host architecture
      architecture_to_use="$host_arch"
      ;;
  esac
fi

# If GDB_ROOT is not set, then figure it out
# from $0.  We need this for gdb's that are
# not installed in /usr/bin.

GDB_ROOT_SET=${GDB_ROOT:+set}
if [ "$GDB_ROOT_SET" != "set" ]
then
  gdb_bin="$0"
  if [ -L "$gdb_bin" ]
  then
    gdb_bin=`readlink "$gdb_bin"`
  fi
  gdb_bin_dirname=`dirname "$gdb_bin"`
  GDB_ROOT=`cd "$gdb_bin_dirname"/../.. ; pwd`
  if [ "$GDB_ROOT" = "/" ]
      then
        GDB_ROOT=
  fi
fi

osabiopts=""

case "$architecture_to_use" in
  i386 | x86_64)
    gdb="${GDB_ROOT}/usr/libexec/gdb/gdb-i386-apple-darwin"
    ;;
  arm*)
    gdb="${GDB_ROOT}/usr/libexec/gdb/gdb-arm-apple-darwin"
      case "$architecture_to_use" in
        armv6) 
          osabiopts="--osabi DarwinV6" 
          ;;
        armv7) 
          osabiopts="--osabi DarwinV7" 
          ;;
        armv7k)
          osabiopts="--osabi DarwinV7K" 
          ;;
        armv7s)
          osabiopts="--osabi DarwinV7S" 
          ;;
        armv7f)
          osabiopts="--osabi DarwinV7F" 
          ;;
        *)
          # Make the REQUESTED_ARCHITECTURE the empty string so
          # we can let gdb auto-detect the cpu type and subtype
          requested_arch=""
          ;;
      esac
      ;;
  *)
    echo "Unknown architecture '$architecture_to_use'; using 'i386' instead.";
    gdb="${GDB_ROOT}/usr/libexec/gdb/gdb-i386-apple-darwin"
    ;;
esac

# If we have a core file and the user didn't specify an architecture, we need
# to set the REQUESTED_ARCH to the architecture to use in case we have a 
# universal executable with a core file (which is always skinny). This is a
# bug in gdb currently that hasn't been fixed. If gdb ever does fix its 
# ability to grab the correct slice from an executable given a core file, 
# then we can take the next 3 lines out.
if [ -z "$requested_arch" -a -n "$core_file" ]
then
  requested_arch=$architecture_to_use;      
fi

if [ ! -x "$gdb" ]
then
    echo "Unable to start GDB: cannot find binary in '$gdb'"
    exit 1
fi

if [ -n "$osabiopts" ]
then
  exec $translate_binary "$gdb" $osabiopts "$@"
fi

if [ -n "$requested_arch" ]
then
  exec $translate_binary "$gdb" --arch "$requested_arch" "$@"
fi

exec $translate_binary "$gdb" "$@"
