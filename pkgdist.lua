#! /usr/libexec/flua

local ucl = require('ucl')

local tar = function (input, output)
	return 0 == os.execute('tar cJf '..output..' '..input)
end

assert(#arg == 1)

if arg[1] == 'src' then
	tar('/usr/src', 'src.txz')
elseif arg[1] == 'tests' then
	tar('/usr/tests', 'tests.txz')
else
	error('Unknown argument '..arg[1])
end

