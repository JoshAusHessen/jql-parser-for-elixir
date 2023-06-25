defmodule DefaultJQLParser do
  @behaviour JQLParser

  @impl JQLParser
  def exec_or(left, right) do
    "(#{left} OR #{right})"
  end

  @impl JQLParser
  def exec_and(left, right) do
    "(#{left} AND #{right})"
  end

  @impl JQLParser
  def exec_not(value) do
    "(NOT #{value})"
  end

  @impl JQLParser
  def exec_not_in(left, right) do
    "(#{left} NOT IN #{right})"
  end

  @impl JQLParser
  def exec_in(left, right) do
    "(#{left} IN #{right})"
  end

  @impl JQLParser
  def exec_is_in(left, right) do
    "(#{left} IS IN #{right})"
  end

  @impl JQLParser
  def exec_is(left, right) do
    "(#{left} IS #{right})"
  end

  @impl JQLParser
  def exec_eq(left, right) do
    "(#{left} = #{right})"
  end

  @impl JQLParser
  def exec_lt(left, right) do
    "(#{left} < #{right})"
  end

  @impl JQLParser
  def exec_gt(left, right) do
    "(#{left} > #{right})"
  end

  @impl JQLParser
  def exec_neq(left, right) do
    "(#{left} != #{right})"
  end

  @impl JQLParser
  def exec_leq(left, right) do
    "(#{left} <= #{right})"
  end

  @impl JQLParser
  def exec_geq(left, right) do
    "(#{left} >= #{right})"
  end

end
