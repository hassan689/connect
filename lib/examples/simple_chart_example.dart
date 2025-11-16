import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:linkster/core/theme/app_theme.dart';

class SimpleChartExample extends StatefulWidget {
  const SimpleChartExample({super.key});

  @override
  State<SimpleChartExample> createState() => _SimpleChartExampleState();
}

class _SimpleChartExampleState extends State<SimpleChartExample> {
  late List<SalesData> _chartData;
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _chartData = getChartData();
    _tooltipBehavior = TooltipBehavior(enable: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C7BE),
        elevation: 0,
        title: Text(
          'Simple Chart Example',
          style: AppTheme.appBarTitle.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Basic Column Chart
            _buildChartCard(
              'Basic Column Chart',
              'Simple bar chart showing sales data',
              SizedBox(
                height: 200,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  primaryYAxis: NumericAxis(),
                  tooltipBehavior: _tooltipBehavior,
                  series: <CartesianSeries>[
                    ColumnSeries<SalesData, String>(
                      dataSource: _chartData,
                      xValueMapper: (SalesData data, _) => data.year,
                      yValueMapper: (SalesData data, _) => data.sales,
                      name: 'Sales',
                      color: const Color(0xFF00C7BE),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Line Chart
            _buildChartCard(
              'Line Chart',
              'Trend line showing sales progression',
              SizedBox(
                height: 200,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  primaryYAxis: NumericAxis(),
                  tooltipBehavior: _tooltipBehavior,
                  series: <CartesianSeries>[
                    LineSeries<SalesData, String>(
                      dataSource: _chartData,
                      xValueMapper: (SalesData data, _) => data.year,
                      yValueMapper: (SalesData data, _) => data.sales,
                      name: 'Sales Trend',
                      color: Colors.blue,
                      width: 3,
                      markerSettings: const MarkerSettings(isVisible: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Pie Chart
            _buildChartCard(
              'Pie Chart',
              'Distribution of sales by category',
              SizedBox(
                height: 200,
                child: SfCircularChart(
                  series: <CircularSeries>[
                    PieSeries<SalesData, String>(
                      dataSource: _chartData,
                      xValueMapper: (SalesData data, _) => data.year,
                      yValueMapper: (SalesData data, _) => data.sales,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.outside,
                      ),
                    ),
                  ],
                  tooltipBehavior: _tooltipBehavior,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Area Chart
            _buildChartCard(
              'Area Chart',
              'Filled area showing sales volume',
              SizedBox(
                height: 200,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  primaryYAxis: NumericAxis(),
                  tooltipBehavior: _tooltipBehavior,
                  series: <CartesianSeries>[
                    AreaSeries<SalesData, String>(
                      dataSource: _chartData,
                      xValueMapper: (SalesData data, _) => data.year,
                      yValueMapper: (SalesData data, _) => data.sales,
                      name: 'Sales Area',
                      color: const Color(0xFF00C7BE).withValues(alpha: 0.3),
                      borderColor: const Color(0xFF00C7BE),
                      borderWidth: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, String description, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.heading4,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }

  List<SalesData> getChartData() {
    return <SalesData>[
      SalesData('2018', 35),
      SalesData('2019', 28),
      SalesData('2020', 34),
      SalesData('2021', 32),
      SalesData('2022', 40),
      SalesData('2023', 45),
    ];
  }
}

class SalesData {
  SalesData(this.year, this.sales);
  final String year;
  final double sales;
} 