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
  def exec_par(value) do
    "(#{value})"
  end

  @impl JQLParser
  def exec_string(value) do
    value = value
      |> String.replace(~r/^["']/, "")
      |> String.replace(~r/["']$/, "")
    "#{value}"
  end

  @impl JQLParser
  def exec_other(value) do
    "#{value}"
  end
end
