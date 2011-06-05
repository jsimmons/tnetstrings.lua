-- tnetstring unit testing, using https://github.com/norman/telescope
local tns = require 'tnetstrings'

context('tnetstrings', function()
    context('parse', function()
        test('general failure', function()
            -- no length
            assert_nil(tns.parse(':hello,'))

            -- no colon
            assert_nil(tns.parse('5hello,'))

            -- incorrect length
            assert_nil(tns.parse('16:hello,'))

            -- invalid type code
            assert_nil(tns.parse('5:hello?'))
            assert_nil(tns.parse('5:hello'))

            -- nested errors
            assert_nil(tns.parse('16:5:hello!5:hello,}'))
            assert_nil(tns.parse('16:5:hello,5:hello!}'))
            assert_nil(tns.parse('16:5:hello,5:hello!]'))
        end)

        test('null', function()
            assert_equal(tns.null(), tns.null)
            assert_equal(tns.parse('0:~'), tns.null)
        end)

        test('blob', function()
            assert_equal(tns.parse('5:Hello,'), 'Hello')
        end)

        test('integer', function()
            assert_equal(tns.parse('5:12345#'), 12345)

            local res = tns.parse('5:hello#')
            assert_nil(res)
        end)

        test('boolean', function()
            assert_equal(tns.parse('4:true!'), true)
            assert_equal(tns.parse('5:false!'), false)

            assert_nil(tns.parse('5:hello!'))
        end)

        test('dict', function()
            local result = tns.parse('16:5:hello,5:world,}')
            assert_equal(result['hello'], 'world')

            assert_empty(tns.parse('0:}'))

            assert_nil(tns.parse('8:5:hello,}'))
            assert_nil(tns.parse('8:5:12345#}'))
        end)

        test('list', function()
            local result = tns.parse('16:5:hello,5:world,]')
            assert_equal(result[1], 'hello')
            assert_equal(result[2], 'world')

            assert_empty(tns.parse('0:]'))
        end)
    end)

    context('dump', function()
        test('general failure', function()
            assert_error(function() tns.dump(function() end) end)
            assert_error(function() tns.dump(nil) end)

            -- A handy userdata is the file object :D
            assert_error(function() tns.dump(io.stdout) end)

            -- Must use string keys
            assert_error(function() tns.dump({'hello'}) end)
        end)

        test('blob', function()
            assert_equal(tns.dump('hello'), '5:hello,')
        end)

        test('number', function()
            assert_equal(tns.dump(9000), '4:9000#')
        end)

        test('boolean', function()
            assert_equal(tns.dump(true), '4:true!')
            assert_equal(tns.dump(false), '5:false!')
        end)

        test('null', function()
            assert_equal(tns.dump(tns.null), '0:~')
        end)

        test('list', function()
            assert_equal(tns.dump(tns.list({'hello', 'world'})), '16:5:hello,5:world,]')
        end)

        test('dict', function()
            assert_equal(tns.dump({hello = 'world'}), '16:5:hello,5:world,}')
        end)
    end)

    context('sanity', function()
        test('boolean', function()
            assert_equal(tns.parse(tns.dump(true)), true)
            assert_equal(tns.parse(tns.dump(false)), false)
        end)

        test('blob', function()
            assert_equal(tns.parse(tns.dump('hello')), 'hello')
        end)

        test('number', function()
            assert_equal(tns.parse(tns.dump(9000)), 9000)
        end)

        test('null', function()
            assert_equal(tns.parse(tns.dump(tns.null)), tns.null)
        end)

        test('list', function()
            local res = tns.parse(tns.dump(tns.list({'hello', 'world'}))) 
            assert_equal(res[1], 'hello')
            assert_equal(res[2], 'world')
        end)

        test('dict', function()
            local res = tns.parse(tns.dump({hello = 'world'}))
            assert_equal(res.hello, 'world')
        end)
    end)
end)
