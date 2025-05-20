defmodule ChatEmpresarial.Usuarios do

    @moduledoc """
  Este módulo gestiona los usuarios conectados al programa y quienes se encuentran activos
  """
alias Erl2exVendored.Cli

  defstruct [:nombre, :pid]

  def usuario(nombre) do

    cliente= %ChatEmpresarial.Usuarios{nombre: nombre, pid: self()}

    case GenServer.call(ChatEmpresarial.Servidor, {:connect, nombre, cliente.pid }) do
       :ok ->
        IO.puts("Usuario #{nombre} conectado.")
        comandos(cliente)

        {:error, mensaje} ->
          IO.puts("Error: #{mensaje}")
    end
  end

  def lista_usuarios() do

    GenServer.call(ChatEmpresarial.Servidor, :lista_usuarios)
  end

  defp comandos(%ChatEmpresarial.Usuarios{}= cliente) do

    IO.puts("Comandos disponibles:")
    IO.puts(" /list  = Ver usuarios conectados")
    IO.puts(" /join [sala]  = Unirse a una sala")
    IO.puts(" /create [sala] = Crear una sala")
    IO.puts(" /send [mensaje] [sala]= Enviar un mensaje a la sala")
    IO.puts(" /exit = Salir del chat")

    listen(cliente)

  end

  defp listen(%ChatEmpresarial.Usuarios{}= cliente) do

    receive do
      {:mensaje, mensaje} -> IO.puts("Nuevo mensaje: #{mensaje}") #espera un mensaje del servidor
      listen(cliente)

    after
      1000->
        comando= IO.gets(">") |> String.trim()  #si no hay mensajes, espera un comando
        procesar_comando(comando, cliente)

    end
  end

  defp procesar_comando("/list", %ChatEmpresarial.Usuarios{}= cliente) do

    usuarios= ChatEmpresarial.Usuarios.lista_usuarios()
    IO.puts("Usuarios conectados:")
    Enum.each(usuarios, fn usuario ->
      IO.puts(" - #{usuario.nombre}")
    end)
    listen(cliente)

  end

  defp procesar_comando("/join" <> sala, %ChatEmpresarial.Usuarios{}= cliente ) do

    join_sala(cliente.nombre, sala)
    IO.puts("Te has unido a la sala #{sala}")
    listen(cliente)
  end

  defp procesar_comando("/create" <> sala, %ChatEmpresarial.Usuarios{}= cliente) do

    create_sala(sala)
    IO.puts("Se ha creado la sala #{sala}")
    listen(cliente)
  end

  defp procesar_comando("/send" <> rest, %ChatEmpresarial.Usuarios{}= cliente) do

    case String.split(rest, "", parts: 2) do
      [mensaje, sala] ->
        send_mensaje(mensaje, sala, cliente.nombre)
        IO.puts("Mensaje enviado a la sala #{sala}: #{mensaje}")
        listen(cliente)

      _ ->
        IO.puts("Comando inválido. Usa /send [mensaje] [sala]")
        listen(cliente)
    end
  end

  defp procesar_comando("/exit", %ChatEmpresarial.Usuarios{}= cliente) do

    GenServer.cast(ChatEmpresarial.Servidor, {:disconnect, cliente.nombre})
    IO.puts("Te has desconectado del chat.")
    :ok
  end

  defp procesar_comando(_comando, %ChatEmpresarial.Usuarios{}= cliente) do

    IO.puts("Comando inválido. Usa /list, /join [sala], /create [sala], /send [mensaje] [sala] o /exit.")
    listen(cliente)
  end

  def create_sala(sala) do

    GenServer.cast(ChatEmpresarial.Servidor, {:create, sala})
  end

  def join_sala(usuario, sala) do

    GenServer.cast(ChatEmpresarial.Servidor, {:join, usuario, sala})
  end

  def send_mensaje(mensaje, sala, usuario) do

    GenServer.cast(ChatEmpresarial.Servidor, {:send, mensaje, sala, usuario})
  end

end
