#! /usr/libexec/flua

local ucl = require('ucl')

local tar_xz = 'XZ_OPTS=--threads=0 tar -cvJf'

local with_exclude = function (cmd, exclude)
	for _, v in ipairs(exclude) do
		cmd = cmd..' --exclude '..v
	end
	return cmd
end

local src = function (path)
	if path == nil then path = ' /usr/src' end
	local exclude = {'.svn', '.zfs', '.git', '@', 'release/dist', 'release/obj'}
	local cmd = with_exclude(tar_xz..' -L src.txz', exclude)
	return 0 == os.execute(cmd..path)
end

local tests = function (path)
	if path == nil then path = ' /usr/tests' end
	return 0 == os.execute(tar_xz..' -L tests.txz'..path)
end

local ports = function (path)
	if path == nil then path = ' /usr/ports' end
	local exclude = {'.svn', '.git', 'distfiles', 'packages', 'INDEX*', 'work'}
	local cmd = with_exclude(tar_xz..' -L ports.txz', exclude)
	return 0 == os.execute(cmd..path)
end

local kernel = function (path)
	if path == nil then path = ' /boot/kernel' end
	return 0 == os.execute(tar_xz..' kernel.txz --exclude *.debug '..path)
end

local base = function (path)
	if path == nil then path = ' /' end
	local exclude = {
		'entropy', 'home', 'sys', 'media/*', 'media/.*', 'mnt/*', 'mnt/.*',
		'net/*', 'net/.*', 'proc/*', 'proc/.*', 'root/*', 'tmp/*', 'tmp/.*',
		'usr/lib32/*', 'usr/lib32/.*', 'usr/local/*', 'usr/local/.*',
		'usr/obj/*', 'usr/obj/.*', 'usr/src/*', 'usr/src/.*', 'zroot'}
	local cmd = with_exclude(tar_xz..' base.txz', exclude)
	return 0 == os.execute(cmd..path)
end

assert(#arg == 1 or #arg == 2, 'Expected 1 or 2 arguments, got '..tostring(#arg))

if arg[1] == 'src' then
	src(arg[2])
elseif arg[1] == 'tests' then
	tests(arg[2])
elseif arg[1] == 'ports' then
	ports(arg[2])
elseif arg[1] == 'kernel' then
	kernel(arg[2])
elseif arg[1] == 'base' then
	base(arg[2])
else
	error('Unknown argument '..arg[1])
end
