import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';

class CoverLetterRoseChart extends StatelessWidget {
  final List<Map<String, dynamic>> roseData;

  const CoverLetterRoseChart({
    super.key,
    required this.roseData,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 300,
      child: Chart(
        data: roseData,
        variables: {
          'name': Variable(
            accessor: (Map map) => map['name'] as String,
          ),
          'value': Variable(
            accessor: (Map map) => map['value'] as num,
            scale: LinearScale(min: 0, marginMax: 0.1),
          ),
        },
        marks: [
          IntervalMark(
            label: LabelEncode(
              encoder: (tuple) => Label(tuple['name'].toString()),
            ),
            shape: ShapeEncode(
              value: RectShape(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            color: ColorEncode(variable: 'name', values: Defaults.colors10),
            elevation: ElevationEncode(value: 5),
          )
        ],
        coord: PolarCoord(startRadius: 0.15),
      ),
    );
  }
}
