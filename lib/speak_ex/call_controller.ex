defmodule ExComm.CallController do
  require Logger
  alias ExComm.AgiResult
  import ExComm.Utils
  use ExComm.CallController.Macros

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
    end
  end 

  def command(function, arguments), do: run_command(:erlagi, function, arguments)

  def originate(to, options \\ [], module) do
    metadata = Keyword.get(options, :controller_metadata, [])
    controller = Keyword.get(options, :controller, :run)
    Agent.start_link(fn -> 
      opts = Keyword.drop(options, [:controller_metadata, :controller])
      |> Keyword.put(:caller_pid, self)
      ExComm.originate(to, opts)
      {{module, controller}, metadata} 
    end) 
  end

  api :answer 
  api :hangup
  api :terminate
  api :enable_music
  api :disable_music
  api :set_callerid
  api :say_digits
  api :say_number
  api :wait_digit
  api :set_variable
  api :log_debug
  api :log_warn
  api :log_notice
  api :log_error
  api :log_verbose
  api :log_dtmf
  api :database_deltree
  api :set_auto_hangup
  api :stream_file
  api :play_custom_tones
  api :play_busy
  api :indicate_busy
  api :play_congestion
  api :indicate_congestion
  api :play_dial
  api :stop_play_tones
  api :record
  api :dial

  #api :play, :stream_file

  def play(call, [h | _] = filenames) when is_list(h) do
    stream_file(call, filenames ++ ['#'])
  end
  def play(call, filename) do
    stream_file(call, [filename, '#'])
  end
  def play!(call, filename_or_list) do
    play(call, filename_or_list)
    call
  end

  #######################
  # Callbacks 

  def new_call(call) do
    variable = :erlagi.get_variable(call, 'caller_pid')
    Logger.debug "caller_pid: #{inspect variable}"

    agent = variable |> :erlang.list_to_pid 
    case Agent.get(agent, &(&1)) do
      {{mod, fun}, metadata} ->
        Agent.stop(agent)
        apply(mod, fun, [call, metadata])
      other -> 
        Logger.error "Failed to get from Agent. Result was #{inspect other}"
        {:error, "Agent failed. Result was #{inspect other}"}
    end
  end

  #######################
  # Private Helpers

  def run_command(module, function, arguments) do
    result = :erlang.apply(module, function, arguments)
    Logger.debug "Result ==> #{inspect result}"
    AgiResult.new result
  end

end

