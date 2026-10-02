defmodule Programa do
  def main do

    recolectores = Datos.recolectores() |> Map.new(&{&1.codigo, &1})
    lotes = Datos.lotes() |> Map.new(&{&1.id, &1})
    pesajes_iniciales = Datos.pesajes()

    linea = Util.leer("Ingrese un pesaje adicional (recolector;lote;dia;kilos;verdes) o Enter para omitir: ", :string)
    pesajes_totales = procesar_pesaje_adicional(linea, pesajes_iniciales)


    {validos, rechazados} = clasificar_pesajes(pesajes_totales, recolectores, lotes)


    liquidaciones = construir_liquidaciones(validos, recolectores)

    Util.imprimir_mensaje(Reportes.generar_r1(rechazados))
    Util.imprimir_mensaje(Reportes.generar_r2(validos, lotes))
    Util.imprimir_mensaje(Reportes.generar_r3(validos))
    Util.imprimir_mensaje(Reportes.generar_r4(liquidaciones))
    Util.imprimir_mensaje(Reportes.generar_r5(validos, recolectores))
    Util.imprimir_mensaje(Reportes.generar_r6(validos, recolectores))
    Util.imprimir_mensaje(Reportes.generar_r7(liquidaciones))
    Util.imprimir_mensaje(Reportes.generar_r8(validos, recolectores, lotes))


    codigo_desprendible = Util.leer("\nIngrese el código del recolector para ver su desprendible: ", :string)
    Util.imprimir_mensaje(Reportes.generar_desprendible(codigo_desprendible, liquidaciones))
  end


  defp procesar_pesaje_adicional("", pesajes), do: pesajes
  defp procesar_pesaje_adicional(linea, pesajes) do
    partes = String.split(linea, ";")
    if length(partes) == 5 do
      [rec, lote, dia_str, kilos_str, verdes_str] = partes
      case {Integer.parse(dia_str), Float.parse(kilos_str <> ".0"), Float.parse(verdes_str <> ".0")} do
        {{dia, ""}, {kilos, _}, {verdes, _}} ->
          nuevo_pesaje = %{recolector: rec, lote: lote, dia: dia, kilos: kilos, verdes: verdes}
          Util.imprimir_mensaje("Pesaje agregado exitosamente a la validación.")
          pesajes ++ [nuevo_pesaje]
        _ ->
          Util.imprimir_mensaje("Pesaje rechazado: formato_invalido")
          pesajes
      end
    else
      Util.imprimir_mensaje("Pesaje rechazado: formato_invalido")
      pesajes
    end
  end

  defp clasificar_pesajes(pesajes, recolectores, lotes) do
    Enum.reduce(pesajes, {[], []}, fn p, {val, rech} ->
      case Validacion.validar_pesaje(p, recolectores, lotes) do
        {:ok, valido} -> {val ++ [valido], rech}
        {:error, motivo, p_err} -> {val, rech ++ [{motivo, p_err}]}
      end
    end)
  end

  defp construir_liquidaciones(validos, recolectores) do
    agrupados_por_recolector = Enum.group_by(validos, & &1.recolector)

    Enum.map(recolectores, fn {codigo, rec} ->
      pesajes_rec = Map.get(agrupados_por_recolector, codigo, [])

      por_dia = Enum.group_by(pesajes_rec, & &1.dia)
      dias_detalle = Map.new(por_dia, fn {dia, pesajes_dia} ->
        kilos_dia = Enum.reduce(pesajes_dia, 0, &(&1.kilos + &2))
        valor_dia = Enum.reduce(pesajes_dia, 0, &(Liquidacion.valor_pesaje(&1.kilos, &1.verdes) + &2))
        bono_dia = Liquidacion.bonificacion_diaria(kilos_dia)
        {dia, %{kilos: kilos_dia, valor: valor_dia, bono: bono_dia}}
      end)

      suma_pesajes = Enum.reduce(dias_detalle, 0, fn {_, d}, acc -> acc + d.valor end)
      bonificaciones = Enum.reduce(dias_detalle, 0, fn {_, d}, acc -> acc + d.bono end)
      kilos_totales = Enum.reduce(dias_detalle, 0, fn {_, d}, acc -> acc + d.kilos end)
      dias_trabajados = map_size(dias_detalle)
      alimentacion = Liquidacion.descuento_alimentacion(dias_trabajados, rec.alimentacion)
      neto = suma_pesajes + bonificaciones - alimentacion

      %{
        codigo: codigo,
        nombre: rec.nombre,
        kilos: kilos_totales,
        suma_pesajes: suma_pesajes,
        bonificaciones: bonificaciones,
        alimentacion_desc: alimentacion,
        neto: neto,
        dias_detalle: dias_detalle
      }
    end)
  end
end
Programa.main()
