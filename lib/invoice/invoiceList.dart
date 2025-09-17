import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pie_chart/pie_chart.dart';
import 'add_invoice_page.dart';
import 'invoice_details.dart';

class InvoiceManagementPage extends StatelessWidget {
  const InvoiceManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice Management"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // 背景绿色
                foregroundColor: Colors.white, // 文字 & 图标白色
                elevation: 4, // 阴影
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // 圆角
                  side: const BorderSide(
                    color: Colors.greenAccent,
                    width: 1.5,
                  ), // 边框
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddInvoicePage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Invoice"),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("invoice").snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No invoices found."));
          }

          // 统计 status 和 payment_method
          Map<String, double> statusData = {};
          Map<String, double> methodData = {};
          for (var d in docs) {
            final data = d.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? "unknown";
            final method = data['payment_method'] as String? ?? "unknown";

            statusData[status] = (statusData[status] ?? 0) + 1;
            methodData[method] = (methodData[method] ?? 0) + 1;
          }

          return Column(
            children: [
              // 📊 上半部：两个饼图
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        dataMap: statusData,
                        chartType: ChartType.ring,
                        chartRadius: MediaQuery.of(context).size.width / 5,
                        chartValuesOptions: const ChartValuesOptions(
                          showChartValuesInPercentage: true,
                        ),
                        legendOptions: const LegendOptions(
                          showLegendsInRow: false,
                          legendPosition: LegendPosition.bottom,
                        ),
                      ),
                    ),
                    Expanded(
                      child: PieChart(
                        dataMap: methodData,
                        chartType: ChartType.ring,
                        chartRadius: MediaQuery.of(context).size.width / 5,
                        chartValuesOptions: const ChartValuesOptions(
                          showChartValuesInPercentage: true,
                        ),
                        legendOptions: const LegendOptions(
                          showLegendsInRow: false,
                          legendPosition: LegendPosition.bottom,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 📋 下半部：invoice 列表
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoiceDetailsPage(
                              invoiceId: data['invoice_id'],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(
                            "Invoice ${data['invoice_id']} - ${data['service_type'] ?? 'N/A'}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            "Date: ${data['created_date'].toDate().toString().substring(0, 10)}",
                          ),
                          trailing: SizedBox(
                            width: 100,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "RM${data['total']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(data['status']),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    data['status'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'unpaid':
      default:
        return Colors.red;
    }
  }
}
