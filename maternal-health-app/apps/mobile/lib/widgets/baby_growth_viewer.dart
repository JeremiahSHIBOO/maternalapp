import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A procedural, stylized 3D illustration. Not a fetal scan or growth measure.
class BabyGrowthViewer extends StatefulWidget {
  const BabyGrowthViewer({super.key, required this.week});
  final int week;

  @override
  State<BabyGrowthViewer> createState() => _BabyGrowthViewerState();
}

class _BabyGrowthViewerState extends State<BabyGrowthViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion =
      AnimationController(vsync: this, duration: const Duration(seconds: 12));
  double _yaw = -.35;
  double _pitch = -.12;
  double _zoom = 1;
  double _startZoom = 1;
  bool _playing = false;
  bool _context = false;
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations && _playing) {
      _motion.stop();
      _playing = false;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
        _motion.stop();
        _motion.value = 0;
        _playing = false;
        _yaw = -.35;
        _pitch = -.12;
        _zoom = 1;
      });

  @override
  Widget build(BuildContext context) {
    final early = widget.week < 9;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const RadialGradient(
            center: Alignment(0, -.3),
            radius: 1.1,
            colors: [Color(0xFFFFF9F4), Color(0xFFF0E3E7)],
          ),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 0),
            child: Row(children: [
              const Expanded(
                  child: Text('A little world of wonder',
                      style: TextStyle(
                          color: Color(0xFF70445E),
                          fontWeight: FontWeight.w600))),
              IconButton(
                  tooltip: 'Reset view',
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt)),
            ]),
          ),
          Semantics(
            label: early
                ? 'Stylized early development concept, educational only'
                : 'Stylized curled baby in three dimensions, educational only',
            hint: _still
                ? 'Still view'
                : 'Drag to rotate. Pinch to zoom. View controls below.',
            child: GestureDetector(
              onScaleStart: _still ? null : (_) => _startZoom = _zoom,
              onScaleUpdate: _still
                  ? null
                  : (details) => setState(() {
                        _yaw += details.focalPointDelta.dx * .012;
                        _pitch = (_pitch + details.focalPointDelta.dy * .008)
                            .clamp(-.65, .65);
                        _zoom = (_startZoom * details.scale).clamp(.75, 1.5);
                      }),
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (_, __) => SizedBox(
                    height: 310,
                    width: double.infinity,
                    child: CustomPaint(
                        key: const ValueKey('baby-mesh'),
                        painter: _BabyPainter(
                          week: widget.week,
                          yaw: _still
                              ? -.35
                              : _yaw +
                                  math.sin(_motion.value * math.pi * 2) * .16,
                          pitch: _still ? -.12 : _pitch,
                          zoom: _still ? 1 : _zoom,
                          contextView: _context,
                        )),
                  ),
                ),
              ),
            ),
          ),
          Text(
              _still
                  ? 'Still illustration'
                  : 'Drag to rotate · Pinch to explore',
              style: Theme.of(context).textTheme.bodySmall),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(alignment: WrapAlignment.center, spacing: 4, children: [
              IconButton(
                  tooltip: 'Rotate left',
                  onPressed: _still ? null : () => setState(() => _yaw -= .3),
                  icon: const Icon(Icons.rotate_left)),
              IconButton(
                  tooltip: 'Rotate right',
                  onPressed: _still ? null : () => setState(() => _yaw += .3),
                  icon: const Icon(Icons.rotate_right)),
              IconButton(
                  tooltip: 'Zoom out',
                  onPressed: _still || _zoom <= .75
                      ? null
                      : () =>
                          setState(() => _zoom = (_zoom - .15).clamp(.75, 1.5)),
                  icon: const Icon(Icons.remove)),
              IconButton(
                  tooltip: 'Zoom in',
                  onPressed: _still || _zoom >= 1.5
                      ? null
                      : () =>
                          setState(() => _zoom = (_zoom + .15).clamp(.75, 1.5)),
                  icon: const Icon(Icons.add)),
              IconButton(
                tooltip: _playing ? 'Pause motion' : 'Play gentle motion',
                onPressed: _still || MediaQuery.of(context).disableAnimations
                    ? null
                    : () => setState(() {
                          _playing = !_playing;
                          if (_playing) {
                            _motion.repeat();
                          } else {
                            _motion.stop();
                          }
                        }),
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        FilterChip(
            label: const Text('Womb context'),
            selected: _context,
            onSelected: (value) => setState(() => _context = value)),
        FilterChip(
            label: const Text('Still view'),
            selected: _still,
            onSelected: (value) => setState(() {
                  _still = value;
                  if (value) {
                    _playing = false;
                    _motion.stop();
                  }
                })),
      ]),
      Slider(
        semanticFormatterCallback: (value) => 'Week ${value.round()}',
        min: 1,
        max: 42,
        divisions: 41,
        value: widget.week.toDouble(),
        onChanged: (value) {
          // The owning card supplies the week selection through notification.
          GrowthWeekNotification(value.round()).dispatch(context);
        },
      ),
      Text(
          early
              ? 'Early development · concept view'
              : widget.week < 28
                  ? 'Growing together · concept view'
                  : 'Getting ready to meet · concept view',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 6),
      const Text(
          'Illustration of typical development. Broad stage changes are stylized; this is not your baby’s scan.',
          style: TextStyle(fontSize: 12, height: 1.5)),
    ]);
  }
}

class GrowthWeekNotification extends Notification {
  const GrowthWeekNotification(this.week);
  final int week;
}

class _Point {
  const _Point(this.x, this.y, this.z);
  final double x, y, z;
}

class _Face {
  const _Face(this.points, this.depth, this.colors);
  final List<Offset> points;
  final double depth;
  final List<Color> colors;
}

/// Tessellated ellipsoid geometry, depth sorted with directional lighting.
class _BabyPainter extends CustomPainter {
  const _BabyPainter(
      {required this.week,
      required this.yaw,
      required this.pitch,
      required this.zoom,
      required this.contextView});
  final int week;
  final double yaw, pitch, zoom;
  final bool contextView;

  _Point _rotate(_Point p) {
    final x = p.x * math.cos(yaw) + p.z * math.sin(yaw);
    final z = -p.x * math.sin(yaw) + p.z * math.cos(yaw);
    return _Point(x, p.y * math.cos(pitch) - z * math.sin(pitch),
        p.y * math.sin(pitch) + z * math.cos(pitch));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 260, size.height / 280) * zoom;
    final center = Offset(size.width / 2, size.height / 2 - 4);
    if (contextView) {
      canvas.drawOval(
          Rect.fromCenter(
              center: center, width: 212 * scale, height: 255 * scale),
          Paint()..color = const Color(0x14B36F83));
      canvas.drawOval(
          Rect.fromCenter(
              center: center, width: 212 * scale, height: 255 * scale),
          Paint()
            ..color = const Color(0x45B36F83)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    canvas.drawOval(
        Rect.fromCenter(
            center: center + Offset(0, 113 * scale),
            width: 130 * scale,
            height: 15 * scale),
        Paint()
          ..color = const Color(0x1870445E)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    final faces = <_Face>[];
    void ellipsoid(_Point c, _Point r, {Color skin = const Color(0xFFE7AC97)}) {
      const rings = 16, segments = 28;
      final normals = <_Point, _Point>{};
      _Point vertex(int i, int j) {
        final latitude = math.pi * i / rings;
        final longitude = math.pi * 2 * j / segments;
        final point = _rotate(_Point(
            c.x + r.x * math.sin(latitude) * math.cos(longitude),
            c.y + r.y * math.cos(latitude),
            c.z + r.z * math.sin(latitude) * math.sin(longitude)));
        normals[point] = _rotate(_Point(
            math.sin(latitude) * math.cos(longitude) / r.x,
            math.cos(latitude) / r.y,
            math.sin(latitude) * math.sin(longitude) / r.z));
        return point;
      }

      Offset project(_Point p) {
        final perspective = 500 / (500 - p.z);
        return center + Offset(p.x, p.y) * scale * perspective;
      }

      for (var i = 0; i < rings; i++) {
        for (var j = 0; j < segments; j++) {
          final a = vertex(i, j),
              b = vertex(i + 1, j),
              c = vertex(i + 1, j + 1),
              d = vertex(i, j + 1);
          for (final tri in [
            [a, b, c],
            [a, c, d]
          ]) {
            final u = _Point(
                tri[1].x - tri[0].x, tri[1].y - tri[0].y, tri[1].z - tri[0].z);
            final v = _Point(
                tri[2].x - tri[0].x, tri[2].y - tri[0].y, tri[2].z - tri[0].z);
            final n = _Point(u.z * v.y - u.y * v.z, u.x * v.z - u.z * v.x,
                u.y * v.x - u.x * v.y);
            final length = math.sqrt(n.x * n.x + n.y * n.y + n.z * n.z);
            if (length < .0001 || n.z <= 0) continue;
            final colors = tri.map((point) {
              final normal = normals[point]!;
              final magnitude = math.sqrt(normal.x * normal.x +
                  normal.y * normal.y +
                  normal.z * normal.z);
              final light = ((-normal.x * .4 - normal.y * .5 + normal.z * .75) /
                      magnitude)
                  .clamp(0.0, 1.0);
              return Color.lerp(
                  const Color(0xFF9A5E61), skin, .42 + light * .58)!;
            }).toList();
            faces.add(_Face(tri.map(project).toList(),
                (tri[0].z + tri[1].z + tri[2].z) / 3, colors));
          }
        }
      }
    }

    if (week < 9) {
      // Abstract early-stage silhouette; deliberately avoids weekly anatomy claims.
      ellipsoid(const _Point(-15, -30, 0), const _Point(31, 38, 27));
      ellipsoid(const _Point(7, 14, -3), const _Point(22, 39, 22));
      ellipsoid(const _Point(-7, 44, 0), const _Point(17, 19, 15));
    } else {
      final maturity = ((week - 9) / 31).clamp(0.0, 1.0);
      final head = 40 - maturity * 5;
      ellipsoid(const _Point(6, 15, -5), _Point(31 + maturity * 5, 48, 28));
      ellipsoid(
          const _Point(-18, -53, 0), _Point(head, head * 1.12, head * .88));
      // Ears, nose and closed eyes sit on the face's forward surface.
      ellipsoid(const _Point(-52, -48, 1), const _Point(6, 10, 5));
      ellipsoid(const _Point(-15, -46, 34), const _Point(5, 6, 5));
      ellipsoid(const _Point(-31, -55, 32), const _Point(6, 1.2, 1),
          skin: const Color(0xFF98635E));
      ellipsoid(const _Point(-5, -55, 32), const _Point(6, 1.2, 1),
          skin: const Color(0xFF98635E));
      // Bent arms and folded legs are separate three-dimensional volumes.
      ellipsoid(const _Point(34, 2, 5), const _Point(12, 26, 12));
      ellipsoid(const _Point(25, 21, 23), const _Point(19, 10, 11));
      ellipsoid(const _Point(8, 17, 29), const _Point(9, 9, 7));
      ellipsoid(const _Point(-23, 0, 5), const _Point(11, 24, 11));
      ellipsoid(const _Point(-22, -14, 22), const _Point(9, 15, 10));
      ellipsoid(const _Point(-22, -27, 28), const _Point(8, 9, 7));
      ellipsoid(const _Point(25, 55, 7), const _Point(21, 22, 19));
      ellipsoid(const _Point(9, 68, 26), const _Point(25, 12, 12));
      ellipsoid(const _Point(-14, 65, 30), const _Point(13, 8, 10));
      ellipsoid(const _Point(-15, 51, -16), const _Point(18, 24, 16));
      ellipsoid(const _Point(-26, 72, 3), const _Point(12, 20, 12));
      ellipsoid(const _Point(-26, 88, 13), const _Point(10, 8, 15));
    }
    faces.sort((a, b) => a.depth.compareTo(b.depth));
    final vertices = ui.Vertices(
        ui.VertexMode.triangles, faces.expand((face) => face.points).toList(),
        colors: faces.expand((face) => face.colors).toList());
    canvas.drawVertices(
        vertices, BlendMode.modulate, Paint()..color = Colors.white);
    vertices.dispose();
  }

  @override
  bool shouldRepaint(covariant _BabyPainter oldDelegate) =>
      week != oldDelegate.week ||
      yaw != oldDelegate.yaw ||
      pitch != oldDelegate.pitch ||
      zoom != oldDelegate.zoom ||
      contextView != oldDelegate.contextView;
}
