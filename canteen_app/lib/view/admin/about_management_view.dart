import 'package:canteen_app/common/extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../common_widget/round_textfield.dart';

class AboutManagementView extends StatefulWidget {
  const AboutManagementView({super.key});

  @override
  State<AboutManagementView> createState() => _AboutManagementViewState();
}

class _AboutManagementViewState extends State<AboutManagementView> {
  List<Map<String, dynamic>> aboutSections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAboutSections();
  }

  Future<void> fetchAboutSections() async {
    try {
      final response = await http.get(
        Uri.parse('${SVKey.baseUrl}about_sections'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          setState(() {
            aboutSections =
                List<Map<String, dynamic>>.from(responseObj[KKey.payload]);
            isLoading = false;
          });
        }
      }
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddEditAboutDialog();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: aboutSections.length,
              itemBuilder: (context, index) {
                final section = aboutSections[index];
                return Card(
                  child: ListTile(
                    title: Text(section['title']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section['subtitle'] ?? ''),
                        const SizedBox(height: 5),
                        Text(
                          section['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showAddEditAboutDialog(section: section);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _showDeleteConfirmationDialog(section['id']);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddEditAboutDialog({Map<String, dynamic>? section}) {
    final titleController = TextEditingController(text: section?['title']);
    final subtitleController =
        TextEditingController(text: section?['subtitle']);
    final descriptionController =
        TextEditingController(text: section?['description']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(section == null ? 'Add About Section' : 'Edit About Section'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RoundTextfield(
                hintText: "Title",
                controller: titleController,
              ),
              const SizedBox(height: 10),
              RoundTextfield(
                hintText: "Subtitle",
                controller: subtitleController,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: "Description",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                maxLines: 5,
                minLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final data = {
                'title': titleController.text,
                'subtitle': subtitleController.text,
                'description': descriptionController.text,
              };

              if (section != null) {
                data['id'] = section['id'];
                await _updateAboutSection(data);
              } else {
                await _addAboutSection(data);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAboutSection(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${SVKey.baseUrl}about_sections'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchAboutSections();
          mdShowAlert(Globs.appName, "About section added successfully", () {});
        }
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  Future<void> _updateAboutSection(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${SVKey.baseUrl}about_sections/${data['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchAboutSections();
          mdShowAlert(
              Globs.appName, "About section updated successfully", () {});
        }
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  void _showDeleteConfirmationDialog(int sectionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete About Section'),
        content:
            const Text('Are you sure you want to delete this about section?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteAboutSection(sectionId);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAboutSection(int sectionId) async {
    try {
      final response = await http.delete(
        Uri.parse('${SVKey.baseUrl}about_sections/$sectionId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchAboutSections();
          mdShowAlert(
              Globs.appName, "About section deleted successfully", () {});
        }
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }
}
