// lib/widgets/route_polylines.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../services/route_service.dart';

/// Builds the road lines from the picked point to the technicians.
/// The selected technician is drawn last, so it sits on top.
List<Polyline> buildRoutePolylines({
  required Map<int, TechnicianRouteData> routes,
  required int? selectedId,
  required Color lineColor,
  required Color selectedColor,
}) {
  final result = <Polyline>[];
  Polyline? selectedLine;

  for (final entry in routes.entries) {
    final route = entry.value;
    if (route.points.length < 2) continue;

    final isSelected = entry.key == selectedId;
    final line = _lineFor(route, isSelected, lineColor, selectedColor);

    if (isSelected) {
      selectedLine = line;
    } else {
      result.add(line);
    }
  }

  if (selectedLine != null) result.add(selectedLine);
  return result;
}

Polyline _lineFor(
    TechnicianRouteData route,
    bool selected,
    Color lineColor,
    Color selectedColor,
    ) {
  // Road servers unreachable: thin faded line, clearly not a road route.
  if (!route.isRoad) {
    return Polyline(
      points: route.points,
      strokeWidth: selected ? 4 : 2.5,
      color: (selected ? selectedColor : lineColor).withValues(alpha: 0.55),
    );
  }

  return Polyline(
    points: route.points,
    strokeWidth: selected ? 6 : 3.5,
    color: selected ? selectedColor : lineColor,
    borderColor: Colors.white,
    borderStrokeWidth: selected ? 2.5 : 1.5,
  );
}