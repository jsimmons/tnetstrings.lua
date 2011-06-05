package = 'tnetstrings'
version = 'scm-0'

source = {
    url = 'git://github.com/jsimmons/tnetstrings.lua.git';
}

description = {
    summary = 'A tnetstrings implementation in Lua';
    license = 'MIT';
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
