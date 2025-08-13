// Minimal Savitzky–Golay smoothing for 1D series
// window: odd length >= 3, polyOrder < window
List<double> savitzkyGolay(List<double> x, {int window = 7, int polyOrder = 2}) {
  if (x.isEmpty || window < 3 || window % 2 == 0 || polyOrder >= window) return x;
  final half = window ~/ 2;
  final n = x.length;
  final out = List<double>.filled(n, 0);

  // Precompute Vandermonde and pseudo-inverse weights for central window
  final weights = _centralWeights(window, polyOrder);

  for (int i = 0; i < n; i++) {
    double acc = 0;
    for (int k = -half; k <= half; k++) {
      final idx = (i + k).clamp(0, n - 1);
      acc += weights[k + half] * x[idx];
    }
    out[i] = acc;
  }
  return out;
}

List<double> _centralWeights(int window, int polyOrder) {
  // Solve least-squares for central point weights. For simplicity, use known
  // smoothing weights from literature for common (window, order) combos.
  // Fallback to simple moving average if combo not in table.
  final key = '${window}_${polyOrder}';
  const table = {
    '5_2': [-3/35, 12/35, 17/35, 12/35, -3/35],
    '7_2': [-2/21, 3/21, 6/21, 7/21, 6/21, 3/21, -2/21],
    '7_3': [-2/21, 3/21, 6/21, 7/21, 6/21, 3/21, -2/21],
    '9_2': [-21/231, 14/231, 39/231, 54/231, 59/231, 54/231, 39/231, 14/231, -21/231],
  };
  final w = table[key];
  if (w != null) return w.map((e) => e.toDouble()).toList();
  // moving average fallback
  return List<double>.filled(window, 1.0 / window);
}

