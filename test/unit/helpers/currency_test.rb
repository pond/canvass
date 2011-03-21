require 'test_helper'

class CurrencyTest < ActiveSupport::TestCase
  test "must have name" do
    c = Currency.new
    assert !c.save
  end

  test "must default to USD" do
    c = Currency.get_best_currency( nil )
    assert c.code == "USD"
  end
  
  test "simplify currency string" do
    str = Currency.simplify( "12,23'", "431" )
    assert str == "1223.431"
  end
  
  test "simplify negative currency string" do
    str = Currency.simplify( "  - 1!2,23'", "431" )
    assert str == "-1223.431"
  end

  test "add currency string components" do
    ary = Currency.add( "12,23'", "43189621", "4", "56810379" )
    assert ary == [ "1228", "0" ]
  end

  test "add negative currency string components" do
    ary = Currency.add( "12,23'", "43189621", "-4", "56810379" )
    assert ary == [ "1218", "86379242" ]
  end

  test "subtract currency string components" do
    ary = Currency.subtract( "12,28'", "0", "4", "56810379" )
    assert ary == [ "1223", "43189621" ]
  end

  test "multiply currency string components by integer in String" do
    ary = Currency.multiply( "12,23'", "431", "5" )
    assert ary == [ "6117", "155" ]
  end

  test "multiply currency string components by negative integer in String" do
    ary = Currency.multiply( "12,23'", "431", "   -5" )
    assert ary == [ "-6117", "155" ]
  end

  test "divide currency string components by integer in String" do
    ary = Currency.divide( "!611,7", "155", "5" )
    assert ary == [ "1223", "431" ]
  end

  test "divide negative currency string components by integer in String" do
    ary = Currency.divide( "-!611,7", "155", "5" )
    assert ary == [ "-1223", "431" ]
  end

  test "multiply currency string components by integer in BigDecimal" do
    ary = Currency.multiply( "12,23'", "431", BigDecimal.new( "5" ) )
    assert ary == [ "6117", "155" ]
  end

  test "multiply negative currency string components by integer in BigDecimal" do
    ary = Currency.multiply( "-12,23'", "431", BigDecimal.new( "5" ) )
    assert ary == [ "-6117", "155" ]
  end

  test "multiply negative currency string components by negative integer in BigDecimal" do
    ary = Currency.multiply( "-12,23'", "431", BigDecimal.new( "-5" ) )
    assert ary == [ "6117", "155" ]
  end

  test "divide currency string components by integer in BigDecimal" do
    ary = Currency.divide( "'6,117", "155", BigDecimal.new( "5" ) )
    assert ary == [ "1223", "431" ]
  end

  test "multiply currency string components by negative fraction in String" do
    ary = Currency.multiply( "12,23'", "431", "-0.25" )
    assert ary == [ "-305", "85775" ]
  end

  test "divide negative currency string components by negative fraction in String" do
    ary = Currency.divide( "-305'", "85775", "-0.25" )
    assert ary == [ "1223", "431" ]
  end

  test "multiply currency string components by negative fraction in BigDecimal" do
    ary = Currency.multiply( "12,23'", "431", BigDecimal.new( "-0.25" ) )
    assert ary == [ "-305", "85775" ]
  end

  test "divide currency string components by negative fraction in BigDecimal" do
    ary = Currency.divide( "-305", "85775", BigDecimal.new( "-0.25" ) )
    assert ary == [ "1223", "431" ]
  end

  test "mathematical rounding algorithm works" do
    c = dummy_currency

    n = c.round( "10.995" )
    assert n = "11.00"

    n = c.round( "10.494" )
    assert n = "10.49"

    n = c.round( "10.495" )
    assert n = "10.50"
  end

  test "round_up rounding algorithm works" do
    c = dummy_currency; c.rounding_algorithm = "round_up"

    n = c.round( "10.991" )
    assert n = "11.00"

    n = c.round( "10.495" )
    assert n = "10.50"

    n = c.round( "10.499" )
    assert n = "10.50"
  end

  test "round_down rounding algorithm works" do
    c = dummy_currency; c.rounding_algorithm = "round_down"

    n = c.round( "10.999" )
    assert n = "10.99"

    n = c.round( "10.495" )
    assert n = "10.49"

    n = c.round( "10.499" )
    assert n = "10.49"
  end

  test "argentinian rounding algorithm works" do
    c = dummy_currency; c.rounding_algorithm = "argentinian"; c.decimal_precision = 4

    # This test is only as good as my understanding of Argentinian rounding!
    # http://stackoverflow.com/questions/5134237/swiss-and-argentinian-currency-fourth-decimal-digit-rounding

    n = c.round( "10.9929" )
    assert n = "10.990"

    n = c.round( "10.9939" )
    assert n = "10.995"

    n = c.round( "10.9979" )
    assert n = "10.995"

    n = c.round( "10.9989" )
    assert n = "11.000"
  end

  test "swiss rounding algorithm works" do
    c = dummy_currency; c.rounding_algorithm = "swiss"; c.decimal_precision = 4

    # This test is only as good as my understanding of Swiss rounding!
    # http://stackoverflow.com/questions/5134237/swiss-and-argentinian-currency-fourth-decimal-digit-rounding

    n = c.round( "10.9259" )
    assert n = "10.90"

    n = c.round( "10.9269" )
    assert n = "10.95"

    n = c.round( "10.9759" )
    assert n = "11.00"

    n = c.round( "10.92" )
    assert n = "10.90"

    n = c.round( "10.93" )
    assert n = "10.95"

    n = c.round( "10.98" )
    assert n = "11.00"
  end

  def dummy_currency
    Currency.new(
      :name               => "Dummy",
      :code               => "DUMMY",
      :rounding_algorithm => "mathematical",
      :integer_template   => "0,000,000,000,000",
      :delimiter          => ".",
      :fraction_template  => "00",
      :decimal_precision  => 2,
      :symbol             => "D",
      :show_after_number  => false
    )
  end
end
