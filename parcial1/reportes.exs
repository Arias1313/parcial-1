defmodule Reportes do
  # Función privada para formatear moneda sin depender del módulo Util
  defp formato_moneda(valor) do
    "$" <> :erlang.float_to_binary(valor * 1.0, [{:decimals, 2}])
  end

  def ranking(liquidaciones, opciones \\ []) do
    campo = Keyword.get(opciones, :campo, :neto)
    orden = Keyword.get(opciones, :orden, :desc)
    limite = Keyword.get(opciones, :limite, length(liquidaciones))

    liquidaciones
    |> Enum.sort_by(&Map.get(&1, campo), orden)
    |> Enum.take(limite)
  end

  def generar_r1(rechazados) do
    lista = Enum.map(rechazados, fn {motivo, p} ->
      "#{p.recolector} | #{p.lote} | #{p.kilos} kg | día #{p.dia} | #{p.verdes}% -> #{motivo}"
    end) |> Enum.join("\n")

    conteos = Enum.frequencies_by(rechazados, fn {motivo, _} -> motivo end)
    resumen = Enum.map(conteos, fn {k, v} -> "#{k}: #{v}" end) |> Enum.join("\n")

    "R1. Pesajes rechazados\n#{lista}\n\nRechazos por motivo\n#{resumen}\n"
  end

  def generar_r2(pesajes_validos, lotes) do
    agrupados = Enum.group_by(pesajes_validos, & &1.lote)

    resultados = Enum.map(lotes, fn {id, lote} ->
      kilos_totales = Map.get(agrupados, id, []) |> Enum.reduce(0, &(&1.kilos + &2))
      rendimiento = if lote.hectareas > 0, do: kilos_totales / lote.hectareas, else: 0.0
      %{nombre: lote.nombre, kilos: kilos_totales, hectareas: lote.hectareas, rendimiento: rendimiento}
    end)

    ordenados = Enum.sort_by(resultados, & &1.rendimiento, :desc)

    lineas = Enum.map(ordenados, fn r ->
      "#{r.nombre} | #{r.kilos} kg | #{r.hectareas} ha | #{:erlang.float_to_binary(r.rendimiento * 1.0, decimals: 2)} kg/ha"
    end)

    "R2. Kilos por lote\n" <> Enum.join(lineas, "\n") <> "\n"
  end

  def generar_r3(pesajes_validos) do
    meta = 400
    agrupados = Enum.group_by(pesajes_validos, & &1.dia)

    resultados_dias = Enum.map(1..6, fn dia ->
      kilos = Map.get(agrupados, dia, []) |> Enum.reduce(0, &(&1.kilos + &2))
      cumple_txt = if kilos >= meta, do: "cumplió la meta", else: "no cumplió la meta"
      {dia, kilos, kilos >= meta, "Día #{dia}: #{kilos} kg -> #{cumple_txt}"}
    end)

    lineas = Enum.map(resultados_dias, fn {_, _, _, txt} -> txt end) |> Enum.join("\n")
    cumplio_todos = Enum.all?(resultados_dias, fn {_, _, cumple, _} -> cumple end)
    cumplio_al_menos = Enum.any?(resultados_dias, fn {_, _, cumple, _} -> cumple end)

    texto_todos = if cumplio_todos, do: "Sí", else: "No"
    texto_al_menos = if cumplio_al_menos, do: "Sí", else: "No"

    "R3. Kilos por día (meta: #{meta} kg)\n#{lineas}\n\n¿Se cumplió la meta todos los días? #{texto_todos}\n¿Se cumplió la meta al menos un día? #{texto_al_menos}\n"
  end

  def generar_r4(liquidaciones) do
    ranking_desc = ranking(liquidaciones, campo: :neto, orden: :desc)
    lineas = ranking_desc |> Enum.with_index(1) |> Enum.map(fn {liq, i} ->
      "#{i}. #{liq.nombre} | #{liq.kilos} kg | #{formato_moneda(liq.suma_pesajes)} | #{formato_moneda(liq.bonificaciones)} | #{formato_moneda(liq.alimentacion_desc)} | #{formato_moneda(liq.neto)}"
    end)
    "R4. Liquidación de la semana\n" <> Enum.join(lineas, "\n") <> "\n"
  end

  def generar_r5(pesajes_validos, recolectores) do
    agrupados_por_dia = Enum.group_by(pesajes_validos, & &1.dia)

    mejores_por_dia = Enum.map(1..6, fn dia ->
      pesajes_dia = Map.get(agrupados_por_dia, dia, [])
      if pesajes_dia == [] do
        {dia, [], 0, "Día #{dia}: sin pesajes"}
      else
        kilos_recolector = Enum.group_by(pesajes_dia, & &1.recolector)
                           |> Enum.map(fn {rec, ps} -> {rec, Enum.reduce(ps, 0, &(&1.kilos + &2))} end)

        max_kilos = Enum.map(kilos_recolector, fn {_, k} -> k end) |> Enum.max()
        empatados = Enum.filter(kilos_recolector, fn {_, k} -> k == max_kilos end)
                    |> Enum.map(fn {cod, _} -> recolectores[cod].nombre end)

        nombres_txt = Enum.join(empatados, ", ")
        {dia, empatados, max_kilos, "Día #{dia}: #{nombres_txt} (#{max_kilos} kg)"}
      end
    end)

    lineas = Enum.map(mejores_por_dia, fn {_, _, _, txt} -> txt end) |> Enum.join("\n")
    ganadores_planos = Enum.flat_map(mejores_por_dia, fn {_, ganadores, _, _} -> ganadores end)

    resumen_ganador = if ganadores_planos == [] do
      "Ningún ganador en la semana."
    else
      conteos = Enum.frequencies(ganadores_planos)
      max_dias = Enum.map(conteos, fn {_, v} -> v end) |> Enum.max()
      mas_veces = Enum.filter(conteos, fn {_, v} -> v == max_dias end) |> Enum.map(fn {k, _} -> k end)
      "Más días como mejor recolector: #{Enum.join(mas_veces, ", ")} (#{max_dias} días)"
    end

    "R5. Mejor recolector de cada día\n#{lineas}\n#{resumen_ganador}\n"
  end

  def generar_r6(pesajes_validos, recolectores) do
    agrupados = Enum.group_by(pesajes_validos, & &1.recolector)

    calificados = for {cod, pesajes} <- agrupados, length(pesajes) >= 3 do
      suma_kilos = Enum.reduce(pesajes, 0, &(&1.kilos + &2))
      suma_pond = Enum.reduce(pesajes, 0, &((&1.verdes * &1.kilos) + &2))
      pond = suma_pond / suma_kilos
      %{codigo: cod, nombre: recolectores[cod].nombre, pond: pond}
    end

    case Enum.sort_by(calificados, & &1.pond, :asc) |> List.first() do
      nil -> "R6. Mejor calidad\nNingún recolector cumple los requisitos.\n"
      mejor -> "R6. Mejor calidad (mínimo 3 pesajes válidos)\n#{mejor.nombre}, con #{Float.round(mejor.pond, 2)}% de verdes ponderado por kilos\n"
    end
  end

  def generar_r7(liquidaciones) do
    total_pagar = Enum.reduce(liquidaciones, 0, &(&1.neto + &2))
    kilos_validos = Enum.reduce(liquidaciones, 0, &(&1.kilos + &2))
    promedio = if kilos_validos > 0, do: total_pagar / kilos_validos, else: 0.0

    "R7. Totales de la semana\nTotal a pagar: #{formato_moneda(total_pagar)}\nKilos válidos: #{kilos_validos} kg\nCosto promedio por kilo: #{formato_moneda(promedio)}\n"
  end

  def generar_r8(pesajes_validos, recolectores, lotes) do
    total_lotes = map_size(lotes)
    agrupados_rec = Enum.group_by(pesajes_validos, & &1.recolector)

    cumplen = Enum.filter(agrupados_rec, fn {_, pesajes} ->
      lotes_unicos = Enum.map(pesajes, & &1.lote) |> Enum.uniq() |> length()
      lotes_unicos == total_lotes
    end) |> Enum.map(fn {cod, _} -> recolectores[cod].nombre end)

    if cumplen == [] do
      "R8. Recolectores que trabajaron en todos los lotes\nNinguno.\n"
    else
      "R8. Recolectores que trabajaron en todos los lotes\n" <> Enum.join(cumplen, "\n") <> "\n"
    end
  end

  def generar_desprendible(codigo, liquidaciones) do
    liq = Enum.find(liquidaciones, &(&1.codigo == codigo))
    if liq do
      dias_txt = Enum.map(liq.dias_detalle, fn {dia, detalle} ->
        "Día #{dia}: #{detalle.kilos} kg pesajes #{formato_moneda(detalle.valor)} bonificación #{formato_moneda(detalle.bono)}"
      end) |> Enum.join("\n")

      """
      Desprendible de pago
      #{liq.nombre} (#{liq.codigo})
      #{dias_txt}
      Suma de pesajes: #{formato_moneda(liq.suma_pesajes)}
      Bonificaciones: #{formato_moneda(liq.bonificaciones)}
      Alimentación (#{map_size(liq.dias_detalle)} días): -#{formato_moneda(liq.alimentacion_desc)}
      Neto a pagar: #{formato_moneda(liq.neto)}
      """
    else
      "No existe un recolector con el código #{codigo}."
    end
  end
end
