#!/bin/sh

# usage: ./pkgdist.sh <option>
# <option> is one of:
# 	- a pkg file, with all dependencies in the same location
# 		(can be local, http://, https://, or ftp://)
#   - 'src'
#   - 'tests'
#   - 'ports'
#   - 'base'
#   - 'base-dbg'
#   - 'kernel'
#   - 'kernels-dbg'
#   - 'minimal'
#   - 'minimal-dbg'

tar_xz="tar -cvJf"
code=0
input_name="${1}"

get_files() {
	temp="${1}"; shift
	package="${1}"; shift
	pkglist="${1}"; shift
	skip_first="${1}"
	for dep in $(pkg info -dq "${package}*"); do
		for old_dep in ${pkglist}; do
			if [ "${old_dep}" = "${dep}" ]; then
				continue 2
			fi
		done
		pkglist="${pkglist} ${dep}"
		get_files "${temp}" "${dep}" "${pkglist}"
	done
	if [ "${skip_first}" != "skip" ]; then
		pkg list "${package}" >> "${temp}"
	fi
}

case ${input_name} in
	src|lib32|base-dbg|kernels-dbg|minimal|minimal-dbg)
		temp=$(mktemp) || exit 1
		get_files "${temp}" "FreeBSD-set-${input_name}"
		${tar_xz} "${input_name}.txz" -nLT "${temp}"
		code=$?
		rm "${temp}"
		;;

	ports)
		${tar_xz} ports.txz -L \
		--exclude .svn --exclude .git --exclude distfiles \
		--exclude packages --exclude INDEX* --exclude work \
		/usr/ports
		code=$?
		;;

	kernel)
		kern=$(pkg info -x FreeBSD-kernel | head -n 1)
		echo Making dist set from "${kern}"
		temp=$(mktemp) || exit 1
		get_files "${temp}" "${kern}" 
		${tar_xz} kernel.txz -T "${temp}"
		code=$?
		rm "${temp}"
		;;

	base)
		temp=$(mktemp) || exit 1
		get_files "${temp}" FreeBSD-set-base
		${tar_xz} base.txz -T "${temp}"
		code=$?
		rm "${temp}"
		;;

	*)
		# install the pkg to a temp folder and package that.
		tempdir=$(mktemp -d) || exit 1
		curdir=$(pwd)
		cd "${tempdir}" || exit 1
		INSTALL_AS_USER=true ASSUME_ALWAYS_YES=true pkg -r . add "${curdir}/${input_name}"

		# remove the pkg-generated files
		rm -r ./var/db/pkg/* ./var/db/pkg/.[!.]*
		[ -n "$(ls -A ./var/db/pkg || :)" ] || rm -r ./var/db/pkg
		[ -n "$(ls -A ./var/db || :)" ] || rm -r ./var/db
		[ -n "$(ls -A ./var || :)" ] || rm -r ./var
		
		# make tarball
		find . | sed 1d | ${tar_xz} "${curdir}/${input_name%pkg}txz" -nT -
		cd "${curdir}" && rm -r "${tempdir}"
		;;
esac

exit "${code}"
