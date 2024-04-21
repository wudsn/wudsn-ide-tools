from testutils import testUtils
test = testUtils()

class Test_Predicates:

    def test_lteq(self):
        test.runFile('tests/sources/predicates_lteq.pas')
        assert test.varCardinal('i') == 64824

    def test_ne(self):
        test.runFile('tests/sources/predicates_ne.pas')
        assert test.varCardinal('i') == 4095

    def test_gt(self):
        test.runFile('tests/sources/predicates_gt.pas')
        assert test.varCardinal('i') == 767

    def test_gteq(self):
        test.runFile('tests/sources/predicates_gteq.pas')
        assert test.varCardinal('i') == 4095

    def test_lt(self):
        test.runFile('tests/sources/predicates_lt.pas')
        assert test.varCardinal('i') == 64768

    def test_eq(self):
        test.runFile('tests/sources/predicates_eq.pas')
        assert test.varCardinal('i') == 258048

