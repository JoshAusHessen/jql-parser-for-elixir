defmodule JQLParser do

  ###
  #Callbacks
  ###

  @callback exec_or(left :: any, right :: any) :: any
  @callback exec_and(left :: any, right :: any) :: any
  @callback exec_not(value :: any) :: any
  @callback exec_not_in(value :: any, value :: any) :: any
  @callback exec_in(value :: any, value :: any) :: any
  @callback exec_is(value :: any, value :: any) :: any
  @callback exec_is_in(value :: any, value :: any) :: any
  @callback exec_eq(value :: any, value :: any) :: any
  @callback exec_lt(value :: any, value :: any) :: any
  @callback exec_gt(value :: any, value :: any) :: any
  @callback exec_neq(value :: any, value :: any) :: any
  @callback exec_leq(value :: any, value :: any) :: any
  @callback exec_geq(value :: any, value :: any) :: any
  #@callback exec_other(value :: any) :: any

  @token_specs [
    %{regex: ~r/^or(?=[ (]|$)/, token: :or},
    %{regex: ~r/^and(?=[ (]|$)/, token: :and},

    %{regex: ~r/^[(]/, token: :par_open},
    %{regex: ~r/^[)]/, token: :par_close},
    %{regex: ~r/^[,]/, token: :comma},

    #expresions
    %{regex: ~r/^not(?=[ (]|$)/, token: :not},
    %{regex: ~r/^is(?=[ (]|$)/, token: :is},
    %{regex: ~r/^in(?=[ (]|$)/, token: :in},

    %{regex: ~r/^=/, token: :eq},
    %{regex: ~r/^<(?!=)/, token: :lt},
    %{regex: ~r/^>(?!=)/, token: :gt},
    %{regex: ~r/^!=/, token: :neq},
    %{regex: ~r/^>=/, token: :geq},
    %{regex: ~r/^<=/, token: :leq},
    #%{regex: ~r/^~/, token: :contains},
    #%{regex: ~r/^!~/, token: :not_contains},

    #literals
    %{regex: ~r/^"[^"]*"/, token: :literal},
    %{regex: ~r/^'[^']*'/, token: :literal},
    %{regex: ~r/^[^ ,;()]+(?=[ (),]|$)/, token: :literal},

    #unused
    %{regex: ~r/^empty(?=[ (]|$)/, token: :empty},
    %{regex: ~r/^-?\d+(?=[ (),]|$)/, token: :int},
    %{regex: ~r/^-?\d*.\d+(?=[ (),]|$)/, token: :float},
    %{regex: ~r/^-?\d*(,\d{3})*.\d+(?=[ (),]|$)/, token: :complex_float},
    %{regex: ~r/^[^ \n,()]+(?=[ (),]|$)/, token: :other},

    #%{regex: ~r/^order by /, token: :order_by},
  ]

  def parse(arg, implementation \\ DefaultJQLParser)

  def parse(string, implementation) when is_binary(string) do
    parse(getTokenList(string), implementation)
  end

  def parse(list, implementation) do
    parse_or(list, implementation)
  end

  ###
  #Tokenizer
  ###
  
  def getTokenList(string, token_specs \\ @token_specs) when is_binary(string) do
    if hasMoreTokens?(string) do
      {token , tail} = getNextToken(string |> String.downcase() |> String.trim(), token_specs)
      [token | getTokenList(tail)]
    else
      []
    end
  end

  defp hasMoreTokens?(string) do
    string != nil and string != ""
  end
  
  defp getNextToken(string, token_specs) do
    spec = Enum.find(token_specs, fn (spec) ->
      Regex.match?(spec.regex, string)
    end)
    if spec != nil do
      [match | _] = Regex.run(spec.regex, string, [:first])
      {{spec.token, match}, String.trim_leading(string, match)}
    end
  end

  ###
  #Parser
  ###

  defp parse_or(list, implementation) do
    case parse_and(list, implementation) do
      {value, []} -> {value, []}
      {valueL, [{:or, _} | tail]} -> 
        {valueR, tail} = parse_or(tail, implementation)
        {implementation.exec_or(valueL, valueR), tail}
      {value, list} -> {value, list}
    end
  end

  defp parse_and(list, implementation) do
    case parse_exp(list, implementation) do
      {value, []} -> {value, []}
      {valueL, [{:and, _} | tail]} -> 
        {valueR, tail} = parse_and(tail, implementation)
        {implementation.exec_and(valueL, valueR), tail}
      {value, list} -> {value, list}
    end
  end

  defp parse_exp([{:par_open, _} | tail], implementation)do
    case parse_or(tail, implementation) do
      {value, []} -> {value, []}
      {value, [{:par_close, _} | tail]} -> {value, tail}
      _ -> nil
    end
  end

  defp parse_exp([{:not, _} | tail], implementation)do
    {value, tail} = parse_exp(tail, implementation)
    {implementation.exec_not(value), tail}
  end

  defp parse_exp([{:literal, left} | tail], implementation)do
    case tail do
      [{:not, _}, {:in, _} | tail] ->
        {right, tail} = parse_list(tail)
        {implementation.exec_not_in(left, right), tail}
      [{:in, _} | tail] ->
        {right, tail} = parse_list(tail)
        {implementation.exec_in(left, right), tail}
      [{:is, _}, {:not, _}, {:literal, right} | tail] ->
        {implementation.exec_is_not(left, right), tail}
      [{:is, _}, {:literal, right} | tail] ->
        {implementation.exec_is(left, right), tail}
      [{:eq, _}, {:literal, right} | tail] -> 
        {implementation.exec_eq(left, right), tail}
      [{:lt, _}, {:literal, right} | tail] -> 
        {implementation.exec_lt(left, right), tail}
      [{:gt, _}, {:literal, right} | tail] -> 
        {implementation.exec_gt(left, right), tail}
      [{:neq, _}, {:literal, right} | tail] -> 
        {implementation.exec_neq(left, right), tail}
      [{:leq, _}, {:literal, right} | tail] -> 
        {implementation.exec_leq(left, right), tail}
      [{:geq, _}, {:literal, right} | tail] -> 
        {implementation.exec_geq(left, right), tail}
      _ -> {left, tail}
    end
  end
  
  defp parse_exp(list, _)do
    {nil, list}
  end

  defp parse_list([{:par_open, _} | tail]) do
    parse_list(tail)
  end

  defp parse_list([{:literal, value}, {:comma, _} | tail]) do
    {value_list, tail} = parse_list(tail)
    {[value | value_list], tail}
  end

  defp parse_list([{:literal, value}, {:par_close, _} | tail]) do
    {[value], tail}
  end

  defp parse_list([{:par_close, _} | tail]) do
    {[], tail}
  end
  
end
