require 'minitest/autorun'
require_relative 'polynomial'

class TestPolynomial < Minitest::Test
  def test_symbol_creation
    x = :x
    assert_equal Term.new({ x: 1 }), x
  end

  def test_term_creation
    term = Term.new({ x: 2, y: 3 }, 5)
    assert_equal 5, term.coefficient
    assert_equal ({ x: 2, y: 3 }), term.variables
  end

  def test_addition
    x = :x
    y = :y
    p1 = x + y
    p2 = Polynomial.new(Term.new({ x: 1 }), Term.new({ y: 1 }))
    assert_equal p1, p2
  end

  def test_multiplication
    x = :x
    y = :y
    p1 = x * y
    p2 = Term.new({ x: 1, y: 1 })
    assert_equal p1, p2
  end

  def test_differentiation_simple
    x = :x
    p = x**3
    dp = p.diff(x)
    expected = Term.new({ x: 2 }, 3)
    assert_equal expected, dp
  end

  def test_differentiation_polynomial
    x = :x
    y = :y
    p = (x**2) * y + x * (y**2)
    dp_dx = p.diff(x)
    expected = 2 * x * y + y**2
    assert_equal expected, dp_dx
  end

  def test_differentiation_constant
    x = :x
    p = 5
    dp = p.diff(x)
    assert_equal 0, dp
  end

  def test_to_s
    x = :x
    y = :y
    p = Term.new({ x: 2, y: 1 }, 3) + Term.new({ x: 1, y: 2 }, 2)
    assert_equal "3*x^2*y + 2*x*y^2", p.to_s
  end

  def test_numeric_coefficients
    x = :x
    p = Term.new({ x: 1 }, 5) + Term.new({}, 3)
    assert_equal "5*x + 3", p.to_s
  end
end