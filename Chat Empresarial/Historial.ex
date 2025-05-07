defmodule Historial do

  @moduledoc """
  Este módulo gestiona el historial de mensajes enviados y recibidos en el chat, l aopcion para guardar
  conversaciones, la busqueda y recuperacion de estos.
  """

  defstruct messages: []

  @doc """
  Agrega un mensaje al historial.
  """
  def add_message(historial, message) do
    %{historial | messages: [message | historial.messages]}
  end

  @doc """
  Obtiene el historial de mensajes.
  """
  def get_history(historial) do
    historial.messages
  end
end
