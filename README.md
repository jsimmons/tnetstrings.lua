tnetstrings.lua
===============

An implementation of [tnetstrings](http://tnetstrings.org/) in Lua 5.1

Install Instructions
--------------------

Easiest method is to use luarocks and the provided rockspec.


Usage
-----

`local tns = require 'tnetstrings'`
Note you must store the return value of require, we don't put anything in the global environment.

`tns.null`
Is a sentinal value used to represent tns null. Since nil in a lua table is equivalent to no value, using a sentinal is the only way to properly encode null.

`tns.parse(data)`
Takes the data and returns a single tns value plus any left over data or nil plus an error message.

`tns.dump(object)`
Has not been implmented yet!
