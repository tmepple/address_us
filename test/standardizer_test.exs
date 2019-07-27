defmodule StandardizerTest do
  use ExUnit.Case

  import AddressUS.Parser.Standardizer

  test "handles double number streets properly" do
    assert handle_double_number_streets("3624 10 TH AVE S.") == "3624 10TH AVE S."
  end

  test "a1" do
    assert handle_double_number_streets("86 21 ST") == "86 21ST"
  end

  test "1" do
    assert handle_double_number_streets("2500 2500 GRAY HWY") == "2500 2500 GRAY HWY"
  end

  test "2" do
    assert handle_double_number_streets("892 4 H RD") == "892 4 H RD"
  end

  test "3" do
    assert handle_double_number_streets("1622 22 ST SE") == "1622 22ND ST SE"
  end

  test "4" do
    assert handle_double_number_streets("703 12 AVE NW") == "703 12TH AVE NW"
  end

  test "5" do
    assert handle_double_number_streets("3508 280 BYPASS") == "3508 280 BYPASS"
  end

  test "6" do
    assert handle_double_number_streets("220 2 ND AVE. E RM 106") == "220 2ND AVE. E RM 106"
  end

  test "7" do
    assert handle_double_number_streets("87 951 AVE 73") == "87 951 AVE 73"
  end

  test "8" do
    assert handle_double_number_streets("2860 170 AVE") == "2860 170TH AVE"
  end

  test "9" do
    assert handle_double_number_streets("201 21 ST") == "201 21ST"
  end

  test "10" do
    assert handle_double_number_streets("201 21 ST ST") == "201 21ST ST"
  end

  test "11" do
    assert handle_double_number_streets("944 46 LN") == "944 46TH LN"
  end

  test "12" do
    assert handle_double_number_streets("669 4 AVE N") == "669 4 AVE N"
  end

  test "13" do
    assert handle_double_number_streets("86 12 TH STREET") == "86 12TH STREET"
  end

  test "14" do
    assert handle_double_number_streets("4740 NW 15 WAY") == "4740 NW 15TH WAY"
  end

  test "15" do
    assert handle_double_number_streets("201 E 21 ST ST") == "201 E 21ST ST"
  end
end
