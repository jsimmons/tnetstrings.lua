tnetstrings.lua
===============

An implementation of [tnetstrings](http://tnetstrings.org/) in Lua 5.1

Install Instructions
--------------------

Easiest method is to use luarocks and the provided rockspec.

    sudo luarocks install https://github.com/jsimmons/tnetstrings.lua/raw/master/rockspecs/tnetstrings-scm-0.rockspec

Once we get dump implemented I'll do a versioned release.

Getting it into your codes
--------------------------

    -- Note that you *must* store the return value of require, we don't put
    -- anything in the global environment.
    local tns = require 'tnetstrings'

API
---

_`tns.null`_

A sentinal used to represent the tns null value. We need this since nil in Lua
is equivalent to no value whereas null is a tns value representing no value.


_`tns.parse(data)`_

Parses a single tns value from the given data, and returns it followed by any
remaining data. In case of parsing errors, it returns nil followed by an error
message.

_`tns.dump(value)`_

Well I'm writing this instead of implementing it. So at the moment it does
absolutely nothing.
