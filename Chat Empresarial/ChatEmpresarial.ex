defmodule ChatEmpresarial do

  @moduledoc """
  Este es el módulo principal del programa de chat empresarial. Aquí se definen las funciones
  """

  use Application

  def start(_type, _args) do
    # Inicia el supervisor y los procesos necesarios para el chat empresarial
    children = [
      ChatEmpresarial.Servidor
    ]

    opts = [strategy: :one_for_one, name: ChatEmpresarial.Supervisor]
    Supervisor.start_link(children, opts)  #modulo de elixir, inicia el servidor
    
  end
end
