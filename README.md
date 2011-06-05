tnetstrings.lua
===============

An implementation of [tnetstrings](http://tnetstrings.org/) in Lua 5.1

Install Instructions
--------------------

Easiest method is to use luarocks and the provided rockspec.

For the latest stable release (1.0.0)

    $ sudo luarocks install https://github.com/jsimmons/tnetstrings.lua/raw/master/rockspecs/tnetstrings-1.0.0-1.rockspec

For the latest from the repository.

    $ sudo luarocks install https://github.com/jsimmons/tnetstrings.lua/raw/master/rockspecs/tnetstrings-scm-0.rockspec


Getting it into your codes
--------------------------

    -- Note that you *must* store the return value of require, we don't put
    -- anything in the global environment.
    local tns = require 'tnetstrings'

API
---

`tns.null`

A sentinal used to represent the tns null value. We need this since nil in Lua
is equivalent to no value whereas null is a tns value representing no value.


`tns.parse(data, expected)`

Takes a data string and returns a single tns value from it. Any remaining data
is also returned. In case of parsing errors, or if the expected type does not
match the type found, then the function returns nil followed by an error
message. For simplicities sake, the expected type is given as a tns string type
code.


`tns.list(tab, n)`

Tells dump to treat the given table as a list (array). n is an optional bound,
otherwise we will use #. Note that since we don't implicitly convert nil to
null, a table with holes will still not work even if you calculate n properly.


`tns.dump(value)`

Dumps the given value and returns its tns representation as a string. Unlike
the parse method, we abort on errors rather than returning an error message.
Supported types are:

* boolean
* number
* string
* table
* `tns.list`
* `tns.null`

