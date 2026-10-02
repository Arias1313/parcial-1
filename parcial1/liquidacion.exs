defmodule Liquidacion do
  @tarifa_base 1000
  @bonificacion_diaria 8000
  @descuento_alimentacion 12000
  @kilos_bono 120

  # Regla 2: Valor de un pesaje
  def valor_pesaje(kilos, verdes) do
    bruto = kilos * @tarifa_base
    cond do
      verdes <= 2 -> bruto * 1.05
      verdes > 2 and verdes <= 5 -> bruto
      verdes > 5 and verdes <= 10 -> bruto * 0.90
      verdes > 10 -> bruto * 0.70
    end
  end

  def bonificacion_diaria(kilos_dia) do
    if kilos_dia >= @kilos_bono, do: @bonificacion_diaria, else: 0
  end


  def descuento_alimentacion(dias_trabajados, true), do: dias_trabajados * @descuento_alimentacion
  def descuento_alimentacion(_dias_trabajados, false), do: 0
end
