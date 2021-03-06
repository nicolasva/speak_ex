defmodule SpeakEx.Router do
  require Logger

  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro router([do: block]) do
    quote do
      Module.register_attribute __MODULE__, :routes,
        accumulate: true, persist: true

      unless Application.get_env(:speak_ex, :router) do
        Application.put_env(:speak_ex, :router, __MODULE__)
      end

      unquote(block)

      def do_router(call) do
        @routes
        |> Enum.reverse
        |> Enum.reduce(nil, &SpeakEx.Router.run_route(call, &1, &2))
      end
    end
  end

  defmacro route(name, module, opts \\ []) do
    quote do
      Module.put_attribute(__MODULE__, :routes,
        {unquote(name), unquote(module), unquote(opts)})
    end
  end

  def run_route(call, {_name, module, opts}, nil) do
    result =
      Enum.all?(opts, fn({k,v}) ->
        new_key = SpeakEx.Utils.translate_channel_variable k
        SpeakEx.Utils.get_channel_variable(call, new_key) == v
      end)

    if result do
      {:ok, apply(module, :run, [call])}
    else
      nil
    end
  end

  def run_route(_call, _route, result) do
    result
  end

end
