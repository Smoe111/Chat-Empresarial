defmodule ChatServer.Application do
  @moduledoc """
  Punto de entrada del servidor de chat. Inicia y supervisa todos los procesos críticos.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Registro de usuarios conectados
      ChatServer.UserRegistry,

      # Gestión de salas de chat
      ChatServer.RoomManager,

      # Persistencia de mensajes
      ChatServer.MessageStore,

      # Supervisión de sesiones de usuario (dinámico)
      {DynamicSupervisor, strategy: :one_for_one, name: ChatServer.UserSupervisor}
    ]

    opts = [strategy: :one_for_one, name: ChatServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
