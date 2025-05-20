defmodule ChatEmpresarial.Historial do

  @moduledoc """
  Este módulo gestiona el historial de mensajes enviados y recibidos en el chat, l aopcion para guardar
  conversaciones, la busqueda y recuperacion de estos.
  Esto permite la flexibilidad del codiggo
  """
defmodule Chat.History do

  @path "historial/"  # Crea una carpeta donde se van a guardar los archivos de historial

  def guardar_mensaje(sala, usuario, mensaje) do
    File.mkdir_p!(@path) # Crea la carpeta si no existe
    hora = DateTime.utc_now() |> DateTime.to_string() # Obtiene la hora y fecha actual del texto
    linea = "#{hora},#{usuario},#{mensaje}\n"
    File.write!("#{@path}#{sala}.csv", linea, [:append]) # [:append] agrega las lineas al final del archivo
  end

  def leer_historial(sala) do
    ruta = "#{@path}#{sala}.csv"

    if File.exists?(ruta) do
      File.stream!(ruta) # lee el archivo linea por linea sin cargar la memoria (.read!)
      |> Stream.map(&String.trim/1)
      |> Stream.map(fn linea ->
        case String.split(linea, ",", parts: 3) do
          [h, u, m] -> {h, u, m}
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1) # elimina las lineas invalidas o nill
    else
      "No hay historial para esta sala."
    end
  end
end

end
