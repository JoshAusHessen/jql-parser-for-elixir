defmodule JQLParser do

  ###
  #Callbacks
  ###

  @callback exec_or(left :: any, right :: any) :: any
  @callback exec_and(left :: any, right :: any) :: any
  @callback exec_par(value :: any) :: any
  @callback exec_not(value :: any) :: any
  @callback exec_string(value :: any) :: any
  @callback exec_other(value :: any) :: any

  @token_specs [
    %{regex: ~r/^or(?=[ (]|$)/, token: :or},
    %{regex: ~r/^and(?=[ (]|$)/, token: :and},

    %{regex: ~r/^[(]/, token: :par_open},
    %{regex: ~r/^[)]/, token: :par_close},

    %{regex: ~r/^not(?=[ (]|$)(?![ ]+in)/, token: :not},
    %{regex: ~r/^empty(?=[ (]|$)/, token: :empty},
    %{regex: ~r/^is[ ]+not /, token: :is_not},
    %{regex: ~r/^is (?!not)/, token: :is},
    %{regex: ~r/^in(?=[ (]|$)/, token: :in},
    %{regex: ~r/^not in(?=[ (]|$)/, token: :not_in},
    #%{regex: ~r/^order by /, token: :order_by},


    %{regex: ~r/^=/, token: :eq},
    %{regex: ~r/^<(?!=)/, token: :lt},
    %{regex: ~r/^>(?!=)/, token: :gt},
    %{regex: ~r/^!=/, token: :neq},
    %{regex: ~r/^>=/, token: :geq},
    %{regex: ~r/^<=/, token: :leq},
    #%{regex: ~r/^~/, token: :contains},
    #%{regex: ~r/^!~/, token: :not_contains},

    #literals
    %{regex: ~r/^"[^"]*"/, token: :string},
    %{regex: ~r/^'[^']*'/, token: :string},
    %{regex: ~r/^-?\d+(?=[ (),]|$)/, token: :int},
    %{regex: ~r/^-?\d*.\d+(?=[ (),]|$)/, token: :float},
    %{regex: ~r/^-?\d*(,\d{3})*.\d+(?=[ (),]|$)/, token: :complex_float},
    %{regex: ~r/^[^ \n]+(?=[ (),]|$)/, token: :other},
    %{regex: ~r/^[^ \n]+$/, token: :other},
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

  defp parse_exp([token | list], implementation)do
    case token do
      {:par_open, _} -> parse_par(list, implementation)
      {:not, _} -> 
        {value, tail} = parse_exp(list, implementation)
        {implementation.exec_not(value), tail}
      {:string, value} -> {implementation.exec_string(value), list}
      {:other, value} -> {implementation.exec_other(value), list}
    end
  end

  defp parse_par(list, implementation) do
    case parse_or(list, implementation) do
      {value, []} -> implementation.exec_par(value)
      {value, [{:par_close, _} | tail]} -> {implementation.exec_par(value), tail}
      _ -> nil
    end
  end

end
