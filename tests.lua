-- tnetstring unit testing, using https://github.com/norman/telescope
local tns = require 'tnetstrings'

context('tnetstrings', function()
    context('parse', function()
        test('general failure modes', function()
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
    end)
end)
