#! /usr/libexec/flua

local ucl = require('ucl')

local tar_xz = 'tar -J --options xz:threads=0'

local src = function ()
	local exclude = '--exclude .svn --exclude .zfs --exclude .git --exclude @ --exclude release/dist --exclude release/obj'
	return 0 == os.execute(tar_xz..' -cvLf src.txz '..exclude..' /usr/src')
end

local tests = function ()
	return 0 == os.execute(tar_xz..' -cvLf tests.txz /usr/tests')
end

local ports = function ()
	local exclude = '--exclude .svn --exclude .git --exclude distfiles --exclude packages --exclude INDEX* --exclude work'
	return 0 == os.execute(tar_xz..' -cvLf ports.txz '..exclude..' /usr/ports')
end

assert(#arg == 1)

if arg[1] == 'src' then
	src()
elseif arg[1] == 'tests' then
	tests()
elseif arg[1] == 'ports' then
	ports()	
else
	error('Unknown argument '..arg[1])
end
