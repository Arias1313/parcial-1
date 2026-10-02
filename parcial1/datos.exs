defmodule Datos do
  def recolectores do
    [
      %{codigo: "R01", nombre: "Pablo Emilio Escobar", alimentacion: true},
      %{codigo: "R02", nombre: "Vinicius Junior", alimentacion: false},
      %{codigo: "R03", nombre: "Juan Sebastian Sanchez", alimentacion: true},
      %{codigo: "R04", nombre: "Patricia Morales", alimentacion: true}
    ]
  end

  def lotes do
    [
      %{id: "L1", nombre: "La Esperanza", hectareas: 3.2},
      %{id: "L2", nombre: "El Paraíso", hectareas: 2.0},
      %{id: "L3", nombre: "La Florida", hectareas: 4.5}
    ]
  end

  def pesajes do
    [
      # Pesajes válidos
      %{recolector: "R01", lote: "L1", dia: 1, kilos: 85, verdes: 2.0},
      %{recolector: "R01", lote: "L2", dia: 1, kilos: 60, verdes: 4.5},
      %{recolector: "R01", lote: "L1", dia: 2, kilos: 105, verdes: 8.0},
      %{recolector: "R02", lote: "L1", dia: 1, kilos: 115, verdes: 1.0},
      %{recolector: "R02", lote: "L3", dia: 2, kilos: 50, verdes: 3.5},
      %{recolector: "R02", lote: "L2", dia: 2, kilos: 72.5, verdes: 2.0},
      %{recolector: "R02", lote: "L3", dia: 3, kilos: 80, verdes: 6.0},
      %{recolector: "R02", lote: "L3", dia: 1, kilos: 125, verdes: 0.5},
      %{recolector: "R03", lote: "L2", dia: 1, kilos: 95, verdes: 2.5},
      %{recolector: "R03", lote: "L3", dia: 2, kilos: 68, verdes: 3.0},
      %{recolector: "R03", lote: "L1", dia: 3, kilos: 90, verdes: 1.8},
      %{recolector: "R03", lote: "L2", dia: 3, kilos: 110, verdes: 7.5},
      %{recolector: "R03", lote: "L1", dia: 3, kilos: 45, verdes: 1.0},
      # Los seis últimos son inválidos a propósito para probar el R1
      %{recolector: "R99", lote: "L1", dia: 1, kilos: 75, verdes: 2.0},
      %{recolector: "R03", lote: "L8", dia: 2, kilos: 62, verdes: 1.5},
      %{recolector: "R04", lote: "L3", dia: 8, kilos: 210, verdes: 4.0},
      %{recolector: "R02", lote: "L2", dia: 3, kilos: -5, verdes: 3.0},
      %{recolector: "R01", lote: "L3", dia: 3, kilos: 290, verdes: 2.5},
      %{recolector: "R01", lote: "L2", dia: 3, kilos: 50, verdes: 115}
    ]
  end
end
