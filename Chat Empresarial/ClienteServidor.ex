defmodule ClienteServidor do
  @moduledoc """
  Este módulo se encarga de manejar la interaccion del cliente y el programa
  """

  def hello do
    :world
  end

  def start do
    {:ok, _pid} = :gen_tcp.connect('localhost', 4000, [:binary, active: false])
    loop()
  end

  defp loop do
    {:ok, socket} = :gen_tcp.accept(:gen_tcp.listen(4000, [:binary, active: false]))
    spawn(fn -> handle_client(socket) end)
    loop()
  end

  defp handle_client(socket) do
    # Handle client communication here
    :ok = :gen_tcp.close(socket)
  end

end
