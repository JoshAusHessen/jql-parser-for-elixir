defmodule JQLParserTest do
  use ExUnit.Case
  doctest JQLParser

  test "or" do
    assert JQLParser.parse("hi or hey") == {"(hi OR hey)", []}
  end
  
  test "or with tail" do
    assert JQLParser.parse("hi or hey tail") == {"(hi OR hey)", [{:literal, "tail"}]}
  end

  test "and" do
    assert JQLParser.parse("hi and hey") == {"(hi AND hey)", []}
  end
  
  test "and with tail" do
    assert JQLParser.parse("hi and hey tail") == {"(hi AND hey)", [{:literal, "tail"}]}
  end

  test "not" do
    assert JQLParser.parse("not hey") == {"(NOT hey)", []}
  end
  
  test "not with tail" do
    assert JQLParser.parse("not hey tail") == {"(NOT hey)", [{:literal, "tail"}]}
  end

  test "string" do
    string = JQLParser.parse("'this is a string'")
    assert string == {"this is a string", []}
  end

  test "string with tail" do
    assert JQLParser.parse("'this is a string' this not") == {"this is a string", [{:literal, "this"}, {:not, "not"}]}
  end

  test "list" do
    assert JQLParser.parse("e in (1, 2, 3)") == {"(e IN [\"1\", \"2\", \"3\"])", []}
  end

  test "empty list" do
    assert JQLParser.parse("e in ()") == {"(e IN [])", []}
  end

  test "open list" do
    assert JQLParser.parse("e in (1, 2") == {"(e IN [\"1\", \"2\"])", []}
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
