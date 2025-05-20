defmodule ChatServer do
  use GenServer

  ## Client API

  def start_link(_) do
    GenServer.start_link(_MODULE_, %{
      users: %{},        # %{username => pid}
      rooms: %{},        # %{room_name => MapSet de usuarios}
      history: %{}       # %{room_name => [%{from: username, content: msg, ts: timestamp}]}
    }, name: _MODULE_)
  end

  def connect(username, pid) do
    GenServer.call(_MODULE_, {:connect, username, pid})
  end

  def create_room(room_name) do
    GenServer.call(_MODULE_, {:create_room, room_name})
  end

  def join_room(username, room_name) do
    GenServer.call(_MODULE_, {:join_room, username, room_name})
  end

  def send_message(username, room_name, message) do
    GenServer.cast(_MODULE_, {:send_message, username, room_name, message})
  end

  def list_users(room_name) do
    GenServer.call(_MODULE_, {:list_users, room_name})
  end

  def get_history(room_name) do
    GenServer.call(_MODULE_, {:get_history, room_name})
  end

  ## Server callbacks

  def init(state), do: {:ok, state}

  def handle_call({:connect, username, pid}, _from, state) do
    if Map.has_key?(state.users, username) do
      {:reply, {:error, "Usuario ya conectado"}, state}
    else
      Process.monitor(pid)
      new_users = Map.put(state.users, username, pid)
      {:reply, :ok, %{state | users: new_users}}
    end
  end

  def handle_call({:create_room, room_name}, _from, state) do
    if Map.has_key?(state.rooms, room_name) do
      {:reply, {:error, "La sala ya existe"}, state}
    else
      new_rooms = Map.put(state.rooms, room_name, MapSet.new())
      new_history = Map.put(state.history, room_name, [])
      {:reply, :ok, %{state | rooms: new_rooms, history: new_history}}
    end
  end

  def handle_call({:join_room, username, room_name}, _from, state) do
    case Map.fetch(state.rooms, room_name) do
      :error -> {:reply, {:error, "Sala no encontrada"}, state}
      {:ok, users} ->
        new_users = MapSet.put(users, username)
        new_rooms = Map.put(state.rooms, room_name, new_users)
        {:reply, :ok, %{state | rooms: new_rooms}}
    end
  end

  def handle_call({:list_users, room_name}, _from, state) do
    users = Map.get(state.rooms, room_name, MapSet.new()) |> MapSet.to_list()
    {:reply, users, state}
  end

  def handle_call({:get_history, room_name}, _from, state) do
    {:reply, Map.get(state.history, room_name, []), state}
  end

  def handle_cast({:send_message, username, room_name, message}, state) do
    timestamp = DateTime.utc_now()
    msg = %{from: username, content: message, ts: timestamp}

    # Actualizar historial
    new_history = Map.update(state.history, room_name, [msg], fn old -> [msg | old] end)

    # Notificar usuarios conectados a la sala
    users = Map.get(state.rooms, room_name, MapSet.new())

    Enum.each(users, fn user ->
      case Map.fetch(state.users, user) do
        {:ok, pid} ->
          send(pid, {:new_message, "[#{room_name}] #{username}: #{message}"})
        :error -> :noop
      end
    end)

    {:noreply, %{state | history: new_history}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # Cuando un usuario se desconecta, lo eliminamos de users y de las salas
    {username, _} = Enum.find(state.users, fn {_user, p} -> p == pid end) || {nil, nil}

    if username do
      new_users = Map.delete(state.users, username)
      new_rooms = Enum.reduce(state.rooms, %{}, fn {room, users}, acc ->
        Map.put(acc, room, MapSet.delete(users, username))
      end)
      {:noreply, %{state | users: new_users, rooms: new_rooms}}
    else
      {:noreply, state}
    end
  end
end
