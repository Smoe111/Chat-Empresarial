defmodule ChatEmpresarial.Servidor do

  @moduledoc """
  Este módulo se encarga de manejar la comunicación entre el servidor y los clientes.
  """
  use GenServer

  def start_link(_) do
      GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  def init(port) do
    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary, active: true, reuseaddr: true])
    {:ok, %{socket: listen_socket}, {:continue, :accept}}
  end

  def handle_continue(:accept, %{socket: listen_socket} = state) do
      {:ok, client_socket}= :gen_tcp.accept(listen_socket)
      Task.start_link(fn -> handle_client(client_socket) end)
      {:noreply, state, {:continue, :accept}}
  end

  defp handle_client(socket) do
      :gen_tcp.send(socket, "Bienvenido al chat. Ingrese su nombre:\n")
      {:ok, name} = :gen_tcp.recv(socket, 0)
      :gen_tcp.send(socket, "Hola #{name}, Usa */help para comandos\n")
      ChatRoom.join_room("General", name, socket)
      loop(socket, name)
  end

  defp loop(socket, name) do
      case :gen_tcp.recv(socket, 0) do
          {:ok, message} ->
              process_msg(message, name, socket)
              loop(socket, name)
          {:error, _} ->
              ChatRoom.leave_room("General", name)
              :gen_tcp.close(socket)
      end
  end

  defp process_msg(msg, name, socket) do
      case String.split(msg) do
        ["*/join", room] -> ChatRoom.join_room(room, name, socket)
        ["*/create", room] -> ChatRoom.create_room(room, name, socket)
        ["*/history"] -> send_history(socket, name)
        _ -> ChatRoom.broadcast("General", "#{name}: #{msg}", socket)
      end
  end

  defp send_history(socket, name) do
      history = ChatRoom.get_history(name)
      :gen_tcp.send(socket, "Historial de mensajes:\n#{Enum.join(history, "\n")}\n")
  end

end
