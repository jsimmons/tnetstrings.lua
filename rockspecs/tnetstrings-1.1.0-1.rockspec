package = 'tnetstrings'
version = '1.1.0-1'

source = {
    url = 'https://github.com/downloads/jsimmons/tnetstrings.lua/tnetstrings-1.1.0.tar.bz2';
}

description = {
    summary = 'A tnetstrings implementation in Lua';
    license = 'MIT/X11';
    maintainer = 'Joshua Simmons <simmons.44@gmail.com>';
    homepage = 'https://github.com/jsimmons/tnetstrings.lua/';
}

dependencies = {
    'lua >= 5.1';
}

build = {
    type = 'builtin';
    modules = {
        tnetstrings = 'tnetstrings.lua';
    };
}
