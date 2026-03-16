#! /usr/libexec/flua

local ucl = require('ucl')

local tar_xz = 'tar -J --options xz:threads=0'

local src = function (path)
	local exclude = '--exclude .svn --exclude .zfs --exclude .git --exclude @ --exclude release/dist --exclude release/obj'
	return 0 == os.execute(tar_xz..' -cvLf src.txz '..exclude..' '..path)
end

local tests = function (path)
	return 0 == os.execute(tar_xz..' -cvLf tests.txz '..path)
end

local ports = function (path)
	local exclude = '--exclude .svn --exclude .git --exclude distfiles --exclude packages --exclude INDEX* --exclude work'
	return 0 == os.execute(tar_xz..' -cvLf ports.txz '..exclude..' '..path)
end

local kernel = function (path)
	return 0 == os.execute(tar_xz..' -cvf kernel.txz --exclude *.debug '..path)
end

assert(#arg == 1 or #arg == 2, 'Expected 1 or 2 arguments, got '..tostring(#arg))

local path = nil
if arg[2] ~= nil then
	path = arg[2]
end

if arg[1] == 'src' then
	if path == nil then path = '/usr/src' end
	src(path)
elseif arg[1] == 'tests' then
	if path == nil then path = '/usr/tests' end
	tests(path)
elseif arg[1] == 'ports' then
	if path == nil then path = '/usr/ports' end
	ports(path)
elseif arg[1] == 'kernel' then
	if path == nil then path = '/boot/kernel' end
	kernel(path)
else
	error('Unknown argument '..arg[1])
end
