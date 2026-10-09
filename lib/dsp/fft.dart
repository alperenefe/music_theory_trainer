import 'dart:math' as math;
import 'dart:typed_data';

/// Yerinde (in-place) radix-2 FFT. [re] ve [im] uzunluğu 2'nin kuvveti olmalı.
final class Fft {
  Fft(this.size)
      : assert(size > 1 && (size & (size - 1)) == 0, 'size 2 nin kuvveti olmalı'),
        _cos = Float64List(size ~/ 2),
        _sin = Float64List(size ~/ 2),
        _rev = Uint32List(size) {
    for (var i = 0; i < size ~/ 2; i++) {
      final a = -2 * math.pi * i / size;
      _cos[i] = math.cos(a);
      _sin[i] = math.sin(a);
    }
    final bits = (math.log(size) / math.ln2).round();
    for (var i = 0; i < size; i++) {
      var x = i;
      var r = 0;
      for (var b = 0; b < bits; b++) {
        r = (r << 1) | (x & 1);
        x >>= 1;
      }
      _rev[i] = r;
    }
  }

  final int size;
  final Float64List _cos;
  final Float64List _sin;
  final Uint32List _rev;

  void transform(Float64List re, Float64List im) {
    assert(re.length == size && im.length == size);
    for (var i = 0; i < size; i++) {
      final j = _rev[i];
      if (j > i) {
        final tr = re[i];
        re[i] = re[j];
        re[j] = tr;
        final ti = im[i];
        im[i] = im[j];
        im[j] = ti;
      }
    }
    for (var len = 2; len <= size; len <<= 1) {
      final half = len >> 1;
      final step = size ~/ len;
      for (var i = 0; i < size; i += len) {
        for (var k = 0; k < half; k++) {
          final wr = _cos[k * step];
          final wi = _sin[k * step];
          final a = i + k;
          final b = a + half;
          final xr = re[b] * wr - im[b] * wi;
          final xi = re[b] * wi + im[b] * wr;
          re[b] = re[a] - xr;
          im[b] = im[a] - xi;
          re[a] += xr;
          im[a] += xi;
        }
      }
    }
  }

  /// Hann pencereli gerçek sinyalin genlik spektrumu (ilk size/2 bin).
  /// [samples] daha kısaysa sıfırla tamamlanır, uzunsa SONDAKİ [size] örnek alınır.
  Float64List magnitudeSpectrum(Float64List samples) {
    final re = Float64List(size);
    final im = Float64List(size);
    final n = math.min(size, samples.length);
    final start = samples.length - n;
    for (var i = 0; i < n; i++) {
      final w = 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1));
      re[i] = samples[start + i] * w;
    }
    transform(re, im);
    final out = Float64List(size ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = math.sqrt(re[i] * re[i] + im[i] * im[i]);
    }
    return out;
  }
}
