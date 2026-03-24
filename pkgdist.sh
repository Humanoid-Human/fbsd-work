#!/bin/sh

# usage: ./pkgdist.sh <file>|src|tests|ports|kernel|base

tar_xz="tar -cvJf"
code=0
input_name="${1}"

get_files() {
	temp="${1}"; shift
	package="${1}"; shift
	pkglist="${1}" || pkglist=""; shift
	skip_first="${1}" || skip_first=""
	for dep in $(pkg info -dq "${package}*"); do
		new=0
		for old_dep in ${pkglist}; do
			if [ "${old_dep}" = "${dep}" ]; then
				new=1
				break
			fi
		done
		if [ "${new}" -eq 0 ]; then
			pkglist="${pkglist} ${dep}"
			get_files "${temp}" "${dep}" "${pkglist}"
		fi
	done
	if [ "${skip_first}" != "skip" ]; then
		pkg list "${package}" >> "${temp}"
	fi
}

case ${input_name} in
	src)
		temp=$(mktemp) || exit 1
		get_files "${temp}" FreeBSD-set-src
		${tar_xz} src.txz -LT "${temp}"
		code=$?
		rm "${temp}"
		;;
	tests)
		temp=$(mktemp) || exit 1
		get_files "${temp}" FreeBSD-tests
		${tar_xz} tests.txz -LT "${temp}"
		code=${?}
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
		# code that would install the pkg to a temp folder and package that
		# currently does not work
		
		#tempdir=$(mktemp -d) || exit 1
		#pkg -o INSTALL_AS_USER=true --rootdir "${tempdir}" install "${input_name}"
		#curdir=$(pwd)
		#cd "${tempdir}" && find . | sed 1d | ${tar_xz} ${curdir}/${input%pkg}txz -T -
		#cd "${curdir}" && rm -r "${tempdir}"

		# extract contents
		tempdir=$(mktemp -d) || exit 1
		tar -xf "${input_name}" -C "${tempdir}"
		curr=$(pwd)
		cd "${tempdir}" || exit 1
		# get name of pkg and prefix from +MANIFEST
		pkg_name=$(grep -E -o "\"name\":\"[^\"]+" +MANIFEST | cut -c 9-)
		prefix=$(grep -E -o "\"prefix\":\"[^\"]+" +MANIFEST | cut -c 11-)
		if [ "${prefix}" != "/" ]; then
			# prefix is assumed to be an absolute path
			# so these end up as ./path/to/prefix
			mkdir -p ".${prefix}" 
			mv ./* ".${prefix}"
			mv ./.* ".${prefix}"
		fi
		rm +MANIFEST +COMPACT_MANIFEST
		# tar the files into an uncompressed archive (sed skips the . entry)
		find . | sed 1d | tar -cvf "${curr}/${pkg_name}.tar" -T -
		cd "${curr}" && rm -r "${tempdir}" || exit 1
		# do the normal steps of gathering dependency files
		temp=$(mktemp) || exit 1
		# skip getting the files of the main package
		# since those would have been in the .pkg
		get_files "${temp}" "${pkg_name}" skip
		tar -rvf "${pkg_name}.tar" -T "${temp}"
		rm "${temp}"
		xz -vT0 "${pkg_name}.tar"
		mv "${pkg_name}.tar.xz" "${pkg_name}.txz"
		;;
esac

exit "${code}"
