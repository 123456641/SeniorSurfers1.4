import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Add Tech Term Screen
class AddTechTermScreen extends StatefulWidget {
  const AddTechTermScreen({Key? key}) : super(key: key);

  @override
  State<AddTechTermScreen> createState() => _AddTechTermScreenState();
}

class _AddTechTermScreenState extends State<AddTechTermScreen> {
  final TextEditingController termController = TextEditingController();
  final TextEditingController definitionController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    termController.dispose();
    definitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tech Term'),
        backgroundColor: const Color(0xFF3B6EA5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: termController,
              decoration: const InputDecoration(
                labelText: 'Tech Term',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: definitionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Definition',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  isSubmitting
                      ? null
                      : () async {
                        String term = termController.text.trim();
                        String definition = definitionController.text.trim();

                        if (term.isEmpty || definition.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in all fields'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          isSubmitting = true;
                        });

                        try {
                          final response =
                              await Supabase.instance.client
                                  .from('tech_glossary')
                                  .insert({
                                    'term': term,
                                    'definition': definition,
                                  })
                                  .select();

                          if (response == null || response.isEmpty) {
                            throw Exception('Failed to insert data.');
                          }

                          print('Insert response: $response');

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tech term added successfully!'),
                            ),
                          );

                          Navigator.pop(context, true);
                        } catch (e) {
                          print('Error saving to Supabase: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to save term: ${e.toString()}',
                              ),
                            ),
                          );
                        } finally {
                          setState(() {
                            isSubmitting = false;
                          });
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B6EA5),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 32,
                ),
              ),
              child:
                  isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

// Tech Glossary Display Screen
class TechGlossaryScreen extends StatefulWidget {
  const TechGlossaryScreen({Key? key}) : super(key: key);

  @override
  State<TechGlossaryScreen> createState() => _TechGlossaryScreenState();
}

class _TechGlossaryScreenState extends State<TechGlossaryScreen> {
  List<Map<String, dynamic>> glossaryItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadGlossaryItems();
  }

  Future<void> loadGlossaryItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('tech_glossary')
          .select()
          .order('term');

      setState(() {
        glossaryItems = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading glossary: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load glossary: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tech Glossary'),
        backgroundColor: const Color(0xFF3B6EA5),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : glossaryItems.isEmpty
              ? const Center(child: Text('No terms added yet'))
              : ListView.builder(
                itemCount: glossaryItems.length,
                itemBuilder: (context, index) {
                  final item = glossaryItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ExpansionTile(
                      title: Text(
                        item['term'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(item['definition']),
                        ),
                      ],
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B6EA5),
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTechTermScreen()),
          );

          if (result == true) {
            loadGlossaryItems();
          }
        },
      ),
    );
  }
}

// Main App
class TechGlossaryApp extends StatelessWidget {
  const TechGlossaryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tech Glossary',
      theme: ThemeData(
        primaryColor: const Color(0xFF3B6EA5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B6EA5)),
        useMaterial3: true,
      ),
      home: const TechGlossaryScreen(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jcnglhmzfgcbieeflzif.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjbmdsaG16ZmdjYmllZWZsemlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3OTk4MzksImV4cCI6MjA1ODM3NTgzOX0.1HL3EQ_dMoLQoK5fF6A9jY3Uu2BGi99DJeVSAV0bMbs',
  );

  runApp(const TechGlossaryApp());
}
