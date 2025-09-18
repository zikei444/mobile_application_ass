import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pie_chart/pie_chart.dart';
import 'add_invoice_page.dart';
import 'invoice_details.dart';

class InvoiceManagementPage extends StatefulWidget {
  const InvoiceManagementPage({super.key});

  @override
  State<InvoiceManagementPage> createState() => _InvoiceManagementPageState();
}

class _InvoiceManagementPageState extends State<InvoiceManagementPage> {
  String _selectedStatus = "All"; // filter
  String _sortBy = "Date"; // sort option

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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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

          // Filter
          var filteredDocs = docs.where((d) {
            if (_selectedStatus == "All") return true;
            return (d['status'] as String?) == _selectedStatus.toLowerCase();
          }).toList();

          // Sort
          filteredDocs.sort((a, b) {
            final da = a.data() as Map<String, dynamic>;
            final db = b.data() as Map<String, dynamic>;
            switch (_sortBy) {
              case "Invoice ID":
                return da['invoice_id'].toString().compareTo(db['invoice_id'].toString());
              case "Amount":
                return (da['total'] as num).compareTo(db['total'] as num);
              case "Date":
              default:
                return db['created_date'].compareTo(da['created_date']); // newest first
            }
          });

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

              // 🔍 Filter + Sort Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    // Filter Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: "Filter by Status",
                          labelStyle: const TextStyle(color: Colors.grey), // label grey
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.green), // default border
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.green, width: 2), // green on focus
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.green), // green when not focused
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: "All", child: Text("All")),
                          DropdownMenuItem(value: "Paid", child: Text("Paid")),
                          DropdownMenuItem(value: "Partial", child: Text("Partial")),
                          DropdownMenuItem(value: "Unpaid", child: Text("Unpaid")),
                        ],
                        onChanged: (val) => setState(() => _selectedStatus = val!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: InputDecoration(
                          labelText: "Sort by",
                          labelStyle: const TextStyle(color: Colors.grey), // label grey
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.green), // default border
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.green, width: 2), // green on focus
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.green), // green when not focused
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: "Date", child: Text("Date")),
                          DropdownMenuItem(value: "Invoice ID", child: Text("Invoice ID")),
                          DropdownMenuItem(value: "Amount", child: Text("Amount")),
                        ],
                        onChanged: (val) => setState(() => _sortBy = val!),
                      ),
                    ),
                  ],
                ),
              ),

              // 📋 Invoice 列表
              Expanded(
                child: ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (ctx, i) {
                    final data = filteredDocs[i].data() as Map<String, dynamic>;
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
                                  "RM${(data['total'] as num).toStringAsFixed(2)}",
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
