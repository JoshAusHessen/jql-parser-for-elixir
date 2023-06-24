defmodule JQLParserTest do
  use ExUnit.Case
  doctest JQLParser

  test "or" do
    assert JQLParser.parse("hi or hey") == {"(hi OR hey)", []}
  end
  
  test "or with tail" do
    assert JQLParser.parse("hi or hey tail") == {"(hi OR hey)", [{:other, "tail"}]}
  end

  test "and" do
    assert JQLParser.parse("hi and hey") == {"(hi AND hey)", []}
  end
  
  test "and with tail" do
    assert JQLParser.parse("hi and hey tail") == {"(hi AND hey)", [{:other, "tail"}]}
  end

  test "not" do
    assert JQLParser.parse("not hey") == {"(NOT hey)", []}
  end
  
  test "not with tail" do
    assert JQLParser.parse("not hey tail") == {"(NOT hey)", [{:other, "tail"}]}
  end

  test "string" do
    assert JQLParser.parse("'this is a string'") == {"this is a string", []}
  end

  test "string with tail" do
    assert JQLParser.parse("'this is a string' this not") == {"this is a string", [{:other, "this"}, {:not, "not"}]}
  end

"""
  test "" do
    assert JQLParser.parse("") == 
  end

  test "" do
    assert JQLParser.parse("") == 
  end

  test "" do
    assert JQLParser.parse("") == 
  end

  test "" do
    assert JQLParser.parse("") == 
  end

  test "" do
    assert JQLParser.parse("") == 
  end

  test "" do
    assert JQLParser.parse("") == 
  end
  """
end
