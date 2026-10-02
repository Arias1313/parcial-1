defmodule Validacion do
  
  def validar_pesaje(pesaje, recolectores, lotes) do
    with {:ok, _} <- validar_recolector(pesaje.recolector, recolectores),
         {:ok, _} <- validar_lote(pesaje.lote, lotes),
         {:ok, _} <- validar_dia(pesaje.dia),
         {:ok, _} <- validar_kilos(pesaje.kilos),
         {:ok, _} <- validar_porcentaje(pesaje.verdes) do
      {:ok, pesaje}
    else
      {:error, motivo} -> {:error, motivo, pesaje} # Retornamos el pesaje para el reporte R1
    end
  end

  defp validar_recolector(codigo, recolectores) do
    if Map.has_key?(recolectores, codigo), do: {:ok, codigo}, else: {:error, :recolector_desconocido}
  end

  defp validar_lote(lote, lotes) do
    if Map.has_key?(lotes, lote), do: {:ok, lote}, else: {:error, :lote_desconocido}
  end

  defp validar_dia(dia) do
    if is_integer(dia) and dia >= 1 and dia <= 6, do: {:ok, dia}, else: {:error, :dia_invalido}
  end

  defp validar_kilos(kilos) do
    if is_number(kilos) and kilos > 0 and kilos <= 250, do: {:ok, kilos}, else: {:error, :kilos_fuera_de_rango}
  end

  defp validar_porcentaje(verdes) do
    if is_number(verdes) and verdes >= 0 and verdes <= 100, do: {:ok, verdes}, else: {:error, :porcentaje_invalido}
  end
end
