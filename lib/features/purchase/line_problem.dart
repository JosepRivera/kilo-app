enum LineProblem {
  unresolved('Elige o crea el insumo'),
  measure('Falta convertir la medida'),
  quantity('Falta la cantidad'),
  cost('Falta el precio'),
  price('Revisa el precio');

  const LineProblem(this.message);

  final String message;
}
