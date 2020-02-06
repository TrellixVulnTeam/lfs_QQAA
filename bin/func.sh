#!/bin/bash
serdate() {
  TZ=UTC date +%Y-%m-%d-%H-%M-%S
};
export LINGUAS=en
lspath() {
  echo "$PATH" | tr ':' '\n'
};
report() {
	echo $(serdate):$( printf '%q ' "$@" running ) >&2;
	"$@";
	x=$?;
	echo $(serdate):$( printf '%q ' "$@" returned $x ) >&2;
	return $x
}
uzcat() {
  if ((!$#)); then
    echo >&2 "usage: uzcat [name] ..."
    return 1;
  fi
  for fn; do
    case "$fn" in
      (*.xz) xzcat "$fn";;
      (*.gz) zcat "$fn";;
      (*.bz2) bzcat "$fn";;
      (*) echo >&2 "IDK how to handle $fn"; exit 1;;
    esac
  done
};
to_src() {
  mkdir -pv $LFS_BLD/
  cd $LFS_BLD/
};
not() {
  if "$@" ; then
    return 1
  else
    return 0
  fi
};
is_function() {
  [ "$(type -t $1)" == function ]
}
if test ! -z "$UNPACK_ONLY"; then
  unpack_only() {
    true;
  };
else
  unpack_only() {
    false
  }
fi
run_func() {
  local step=$1
  local skip_file="$LFS_BLD/$dir/.$step.done"
  test -e $skip_file && return 0;
  set -- $all_steps
  while test $1 != $step; do
    shift
  done
  (($#)) && rm -vf $(printf '.%s.done\n' "$@" )
  set -- ${pkg}${pass}_$step ${pkg}_$step generic_$step
  local func
  for func; do 
    if is_function $func; then
      report $func && serdate> "$skip_file" && return 0
      return 1
    fi
  done
  exit 1
}
pkg_list=
add_pkg() {
  pkg_list="$pkg_list $*"
};
build_pkg() {
  echo >&2 "building pkg $pkg ${pass+pass ${pass#_} }in $dir"
  if test ! -d "$dir"; then
    if is_function "${pkg}${pass}_unpack"; then
      "${pkg}${pass}_unpack"
    elif is_function "${pkg}_unpack"; then
      "${pkg}_unpack"
    else
      generic_unpack;
    fi
    mkdir -pv ${dir}
  fi
  unpack_only && return 0
  all_steps="preconfig config build preinstall install postinstall test"
  for step in $all_steps; do
    cd $LFS_BLD/$dir
    run_func $step
  done
};
generic_preinstall() {
  true;
};
generic_preconfig() {
  true;
};
archive_name() {
  eval set -- $LFS_ARC/$pkg*.tar.*
  if (($# != 1)); then
    echo >&2 "expected to find exactly one package, got this:"
    printf >&2 "  %s\n" "$@"
    return 1;
  fi
  arc="$1"
};
generic_unpack() {
  if test -z "$arc"; then
    local arc
    archive_name
  fi
  test -z "$arc" && { echo >&2 "no arc for $pkg" ; exit 1; }
  test -e "$arc" || { echo >&2 "$arc does not exist" ; exit 1; }
  set -- $( uzcat "$arc" | tar -xv | sed 's,/.*$,,' | sort -u )
  if (($# != 1)); then
    echo >&2 "expected to find exactly one dir name, got this:"
    printf >&2 "  %s\n" "$@"
    return 1;
  fi
  mv -v "$1" "$pkg"
}
generic_build() {
  make -j 8 || make -j 1
}
generic_install() {
  make install
};
generic_test() {
  true;
};
generic_postinstall() {
  true;
};
generic_builddir() {
  dir=$pkg
};
build_all() {
  echo $(serdate): starting build
  set -e
  if test ! -d "$LFS" ; then
    echo >&2 "LFS=($LFS)" which does not point to a dir.
    return 1;
  fi
  for i in $pkg_list; do
    set -- ${i/_/ }
    case $# in
      (1) pkg="$1";;
      (2) pkg="$1"; local pass="_$2";;
      (*) 
        echo >&2 expected one or two results from "$i"
        exit 1
        ;;
    esac
    to_src
    if is_function "${pkg}${pass}_builddir"; then
      "${pkg}${pass}_builddir"
    elif is_function "${pkg}_builddir"; then
      "${pkg}_builddir";
    else
      generic_builddir
    fi
    test ! -z "$dir"
    build_pkg $pkg $pass 
    unset pass pkg dir
  done
  post_build_all
  echo $(serdate): build complete
};
