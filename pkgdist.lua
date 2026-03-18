#! /usr/libexec/flua

local ucl = require('ucl')

local tar_xz = 'XZ_OPTS=--threads=0 tar -cvJf '

local repeat_opt = function (opt, table)
	local s = ' '
	for _, v in ipairs(table) do
		s = s..opt..' '..v..' '
	end
	return s
end

local src = function (path)
	if path == nil then path = '/usr/src' end
	local exclude = {'.svn', '.zfs', '.git', '@', 'release/dist', 'release/obj'}
	local rep = repeat_opt('--exclude', exclude)
	return 0 == os.execute(tar_xz..'-L src.txz'..rep..path)
end

local tests = function (path)
	if path == nil then path = '/usr/tests' end
	return 0 == os.execute(tar_xz..'-L tests.txz '..path)
end

local ports = function (path)
	if path == nil then path = '/usr/ports' end
	local exclude = {'.svn', '.git', 'distfiles', 'packages', 'INDEX*', 'work'}
	local rep = repeat_opt('--exclude', exclude)
	return 0 == os.execute(tar_xz..'-L ports.txz'..cmd..path)
end

local kernel = function (path)
	if path == nil then path = '/boot/kernel' end
	return 0 == os.execute(tar_xz..'kernel.txz --exclude *.debug '..path)
end

local base = function (path)
	if path == nil then path = '/' end
	local include = {
		'/COPYRIGHT', '/bin', '/boot', '/dev', '/etc', '/lib', '/libexec', '/media',
		'/mnt', '/net', '/proc', '/rescue', '/root', '/sbin', '/tmp', '/usr', '/var'
	}
	local exclude = {
		'/dev/*', '/dev/.*', '/media/*', '/media/.*', '/mnt/*', '/mnt/.*', '/net/*',
		'/net/.*', '/proc/*', '/proc/.*', '/tmp/*', '/tmp/.*', '/usr/src/*',
		'/usr/src/.*', '/usr/obj/*', '/usr/obj/.*','/usr/lib32/*', '/usr/lib32/.*',
		'/usr/local/*', '/usr/local/.*', '/var/[!y]*/*', '/var/y[!p]*/*' -- don't exclude contents of /var/yp 
	}
	local inc_opts = repeat_opt('--include', include)
	local exc_opts = repeat_opt('--exclude', exclude)
	return 0 == os.execute(tar_xz..'base.txz'..inc_opts..exc_opts..path)
end

assert(#arg == 1 or #arg == 2, 'Expected 1-2 arguments, got '..tostring(#arg))

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
