defmodule JQLParser do

  @token_specs [
    %{regex: ~r/^or(?=[ (]|$)/, token: :or},
    %{regex: ~r/^and(?=[ (]|$)/, token: :and},
    %{regex: ~r/^not(?=[ (]|$)(?![ ]+in)/, token: :not},

    %{regex: ~r/^empty(?=[ (]|$)/, token: :empty},
    %{regex: ~r/^is[ ]+not /, token: :is_not},
    %{regex: ~r/^is (?!not)/, token: :is},
    %{regex: ~r/^in(?=[ (]|$)/, token: :in},
    %{regex: ~r/^not in(?=[ (]|$)/, token: :not_in},
    #%{regex: ~r/^order by /, token: :order_by},

    %{regex: ~r/^[(]/, token: :par_open},
    %{regex: ~r/^[)]/, token: :par_close},

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

  def parse(string) when is_binary(string) do
    parse(getTokenList(string))
  end

  def parse(list) do
    parseOR(list)
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

  defp parseOR(list) do
    case parseAND(list) do
      {value, []} -> {value, []}
      {valueL, [{:or, _} | tail]} -> 
        {valueR, tail} = parseOR(tail)
        {"(#{valueL} OR #{valueR})", tail}
      {value, list} -> {value, list}
    end
  end

  defp parseAND(list) do
    case parseEXP(list) do
      {value, []} -> {value, []}
      {valueL, [{:and, _} | tail]} -> 
        {valueR, tail} = parseAND(tail)
        {"(#{valueL} AND #{valueR})", tail}
      {value, list} -> {value, list}
    end
  end

  defp parseEXP([token | list])do
    case token do
      {:par_open, _} -> parseEXP_par_open(list)
      {:not, _} -> parseEXP_not(list)
      {:string, value} -> parseEXP_string(value, list)
      token -> parseEXP_other([token | list])
    end
  end

  defp parseEXP_par_open(list) do
    case parseOR(list) do
      {value, []} -> "(#{value})"
      {value, [{:par_close, _} | tail]} -> {"(#{value})", tail}
      _ -> nil
    end
  end

  defp parseEXP_not(list) do
    {value, tail} = parseEXP(list)
    {"(NOT #{value})", tail}
  end

  defp parseEXP_string(string, list) do
    value = string
      |> String.replace(~r/^["']/, "")
      |> String.replace(~r/["']$/, "")
    {value, list}
  end
  
  defp parseEXP_other([token | list]) do
    case token do
      {:other, value} -> {value, list}
    end
  end
end
