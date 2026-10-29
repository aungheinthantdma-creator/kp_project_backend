import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const KpAstrologyApp());
}

class KpAstrologyApp extends StatelessWidget {
  const KpAstrologyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KP Astrologer Aung Hein Thant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
        fontFamily: 'Pyidaungsu', 
      ),
      home: const KpHomePage(),
    );
  }
}

// --- ပထမစာမျက်နှာ (Welcome Page) ---
class KpHomePage extends StatelessWidget {
  const KpHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F3),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('KP ဗေဒင် ဇာတာဖွဲ့နှင့် အဟောစနစ်', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/app_logo.png', height: 220),
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('ဆရာအောင်ဟိန်းသန့် ၏\nKP ဗေဒင်ဆော့ဖ်ဝဲလ်မှ ကြိုဆိုပါသည်', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), height: 1.5)),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const KpFormPage()));
                },
                icon: const Icon(Icons.calculate),
                label: const Text('ဇာတာဖွဲ့ရန် စတင်ပါ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2980B9), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- ဒုတိယစာမျက်နှာ (အချက်အလက် ထည့်သွင်းရန် ဖောင်) ---
class KpFormPage extends StatefulWidget {
  const KpFormPage({super.key});

  @override
  State<KpFormPage> createState() => _KpFormPageState();
}

class _KpFormPageState extends State<KpFormPage> {
  final _nameController = TextEditingController();
  final _yearController = TextEditingController(text: "1990");
  final _monthController = TextEditingController(text: "7");
  final _dayController = TextEditingController(text: "22");
  final _hourController = TextEditingController(text: "2");
  final _minuteController = TextEditingController(text: "56");
  
  // Lat, Lon လက်တလော သီးသန့်ရိုက်ထည့်ရန် Controller များ
  final _latController = TextEditingController(text: "22.33");
  final _lonController = TextEditingController(text: "96.79");

  String _selectedCity = '22.33,96.79'; 
  bool _isLoading = false;

  final Map<String, String> _cities = {
    '22.33,96.79': 'နောင်ချို (Naungcho)',
    '21.97,96.08': 'မန္တလေး (Mandalay)',
    '16.80,96.15': 'ရန်ကုန် (Yangon)',
    'custom': '✍️ အခြားမြို့ (Lat, Lon ကိုယ်တိုင်ရိုက်ရန်)'
  };

  Future<void> _calculateChart() async {
    if (_yearController.text.isEmpty || _monthController.text.isEmpty || _dayController.text.isEmpty || _hourController.text.isEmpty || _minuteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ ကျေးဇူးပြု၍ မွေးနှစ်၊ လ၊ ရက်၊ အချိန်များကို ပြည့်စုံစွာ ထည့်ပါ။')));
      return;
    }

    setState(() { _isLoading = true; });

    double h = double.tryParse(_hourController.text) ?? 0;
    double m = double.tryParse(_minuteController.text) ?? 0;
    double decimalHour = h + (m / 60.0);
    
    double lat = 22.33;
    double lon = 96.79;

    if (_selectedCity == 'custom') {
      lat = double.tryParse(_latController.text) ?? 22.33;
      lon = double.tryParse(_lonController.text) ?? 96.79;
    } else {
      List<String> coords = _selectedCity.split(',');
      lat = double.parse(coords[0]);
      lon = double.parse(coords[1]);
    }

    Map<String, dynamic> requestData = {
      "year": int.parse(_yearController.text),
      "month": int.parse(_monthController.text),
      "day": int.parse(_dayController.text),
      "hour": decimalHour,
      "lat": lat,
      "lon": lon
    };

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/calculate-chart'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KpResultPage(
                personName: _nameController.text.isEmpty ? "အမည်မသိ" : _nameController.text,
                resultData: data,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ ဆာဗာ ချိတ်ဆက်မှု အမှားဖြစ်နေပါသည်')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ API ချိတ်ဆက်၍မရပါ။ Python Backend လည်ပတ်နေခြင်း ရှိမရှိ စစ်ဆေးပါ။')));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: const Text('အချက်အလက် ထည့်သွင်းရန်', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ဇာတာရှင်အမည်', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(controller: _nameController, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), hintText: 'အမည်ရိုက်ထည့်ပါ')),
              const SizedBox(height: 20),
              
              const Text('မွေးသက္ကရာဇ်', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _yearController, keyboardType: TextInputType.number, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), hintText: 'ခုနှစ်'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _monthController, keyboardType: TextInputType.number, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), hintText: 'လ'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _dayController, keyboardType: TextInputType.number, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), hintText: 'ရက်'))),
                ],
              ),
              const SizedBox(height: 20),

              const Text('မွေးဖွားချိန် (အချိန်)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _hourController, keyboardType: TextInputType.number, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), hintText: 'နာရီ (0-23)'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _minuteController, keyboardType: TextInputType.number, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), hintText: 'မိနစ် (0-59)'))),
                ],
              ),
              const SizedBox(height: 20),

              // မွေးဖွားရာမြို့ (City Dropdown)
              const Text('မွေးဖွားရာမြို့ (City / Location)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade400)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCity,
                    items: _cities.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() { _selectedCity = val; });
                    },
                  ),
                ),
              ),

              // အကယ်၍ 'အခြားမြို့' ကို ရွေးထားမှသာ Lat, Lon ရိုက်ထည့်ရန် Box ပေါ်လာမည်
              if (_selectedCity == 'custom') ...[
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          labelText: 'Latitude (ဥပမာ - 21.97)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _lonController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          labelText: 'Longitude (ဥပမာ - 96.08)',
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _calculateChart,
                  icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.analytics),
                  label: Text(_isLoading ? 'တွက်ချက်နေပါသည်...' : 'ဇာတာဖွဲ့၍ ဟောစာတမ်းထုတ်မည်', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- တတိယစာမျက်နှာ (ရလဒ်ပြသရန် မျက်နှာပြင် အပြည့်အစုံ) ---
class KpResultPage extends StatelessWidget {
  final String personName;
  final Map<String, dynamic> resultData;

  const KpResultPage({super.key, required this.personName, required this.resultData});

  Widget _buildRasiChart() {
    Map<String, List<String>> chart = {
      "မိဿ": [], "ပြိဿ": [], "မေထုန်": [], "ကရကဋ်": [], "သိဟ်": [], "ကန်": [],
      "တူ": [], "ဗြိစ္ဆာ": [], "ဓနု": [], "မကာရ": [], "ကုံ": [], "မိန်": []
    };

    String lagnaSign = "";
    if (resultData['cusps'] != null && resultData['cusps'].isNotEmpty) {
      lagnaSign = resultData['cusps'][0]['sign'] ?? "မိဿ";
      chart[lagnaSign]?.add("လဂ်");
    }

    if (resultData['planets'] != null) {
      for (var p in resultData['planets']) {
        if (p['sign'] != null) chart[p['sign']]?.add(p['name']);
      }
    }

    Widget box(String sign) {
      return Container(
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.deepOrange)),
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sign, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Expanded(child: Center(child: Text(chart[sign]?.join('\n') ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)))),
          ],
        ),
      );
    }
    Widget emptyBox() => Container(decoration: BoxDecoration(color: const Color(0xFFFCF6E5), border: Border.all(color: Colors.transparent)));

    return SizedBox(
      width: double.infinity,
      height: 350,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(child: Row(children: [Expanded(child: box("မိန်")), Expanded(child: box("မိဿ")), Expanded(child: box("ပြိဿ")), Expanded(child: box("မေထုန်"))])),
              Expanded(child: Row(children: [Expanded(child: box("ကုံ")), Expanded(child: emptyBox()), Expanded(child: emptyBox()), Expanded(child: box("ကရကဋ်"))])),
              Expanded(child: Row(children: [Expanded(child: box("မကာရ")), Expanded(child: emptyBox()), Expanded(child: emptyBox()), Expanded(child: box("သိဟ်"))])),
              Expanded(child: Row(children: [Expanded(child: box("ဓနု")), Expanded(child: box("ဗြိစ္ဆာ")), Expanded(child: box("တူ")), Expanded(child: box("ကန်"))])),
            ],
          ),
          const Center(child: Text("ရာသီစက်", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rp = resultData['ruling_planets'] ?? {};
    final crp = resultData['current_ruling_planets'] ?? resultData['current_rp']; 
    final daily = resultData['daily'] ?? {};
    final pData = resultData['predictions']?['combined'];
    final dashas = resultData['dasha_periods'] ?? resultData['dashas'] ?? [];
    final cusps = resultData['cusps'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F3),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('$personName ၏ ဇာတာခွင်', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      // PDF ထုတ်ရန် ခလုတ် (Download Button)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // ဆရာ့ Backend ရှိ PDF ထုတ်မည့် API ကို ဤနေရာမှ ချိတ်ဆက်နိုင်ပါသည်။
          // ယခုလောလောဆယ် အလုပ်လုပ်ကြောင်းပြသရန် SnackBar ဖြင့် အသိပေးထားပါသည်။
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📥 ဇာတာကို PDF ဖြင့် သိမ်းဆည်းနေပါသည်...'),
              backgroundColor: Color(0xFF27AE60),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.download, color: Colors.white),
        label: const Text('ဇာတာသိမ်းမည်', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD35400),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ရာသီစက် (Rasi Chart)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            const SizedBox(height: 10),
            _buildRasiChart(),
            const SizedBox(height: 25),

            if (cusps.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ဘာဝ ၁၂ ပါး (12 Cusps)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(const Color(0xFF2980B9)),
                      headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columns: const [
                        DataColumn(label: Text('ဘာဝ')),
                        DataColumn(label: Text('ရာသီ')),
                        DataColumn(label: Text('ရာသီသခင်')),
                        DataColumn(label: Text('နက္ခတ်သခင်')),
                        DataColumn(label: Text('ဆပ် (Sub)')),
                      ],
                      rows: List.generate(cusps.length, (index) {
                        var c = cusps[index];
                        return DataRow(cells: [
                          DataCell(Text((index + 1).toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(c['sign'] ?? '-')),
                          DataCell(Text(c['sign_lord'] ?? '-')),
                          DataCell(Text(c['star_lord'] ?? '-')),
                          DataCell(Text(c['sub_lord'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange))),
                        ]);
                      }),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),

            const Text('ဂြိုဟ်ရပ်တည်မှု (Star & Sub Lords)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xFF8E44AD)),
                headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                border: TableBorder.all(color: Colors.grey.shade300),
                columns: const [
                  DataColumn(label: Text('ဂြိုဟ်')),
                  DataColumn(label: Text('ရာသီ')),
                  DataColumn(label: Text('နက္ခတ်သခင်')),
                  DataColumn(label: Text('ဆပ် (Sub)')),
                ],
                rows: List.generate(resultData['planets']?.length ?? 0, (index) {
                  var p = resultData['planets'][index];
                  return DataRow(cells: [
                    DataCell(Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                    DataCell(Text(p['sign'] ?? '-')),
                    DataCell(Text(p['star_lord'] ?? '-')),
                    DataCell(Text(p['sub_lord'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange))),
                  ]);
                }),
              ),
            ),
            const SizedBox(height: 25),

            const Text('စိုးမိုးဂြိုဟ်များ (Ruling Planets)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF4ECF7), borderRadius: BorderRadius.circular(8), border: const Border(left: BorderSide(color: Color(0xFF8E44AD), width: 4))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⭐ မူလ RPs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF8E44AD))),
                        const SizedBox(height: 8),
                        Text('လဂ်ရာသီ: ${rp["lagna_sign_lord"] ?? "-"}'),
                        Text('လဂ်နက္ခတ်: ${rp["lagna_star_lord"] ?? "-"}'),
                        Text('စန်းရာသီ: ${rp["moon_sign_lord"] ?? "-"}'),
                        Text('စန်းနက္ခတ်: ${rp["moon_star_lord"] ?? "-"}'),
                        Text('နေ့နံ: ${rp["day_lord"] ?? "-"}'),
                      ],
                    ),
                  ),
                ),
                if (crp != null) const SizedBox(width: 10),
                if (crp != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFE8F6F3), borderRadius: BorderRadius.circular(8), border: const Border(left: BorderSide(color: Color(0xFF1ABC9C), width: 4))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚡ ယခုလက်ရှိ RPs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF16A085))),
                          const SizedBox(height: 8),
                          Text('လဂ်ရာသီ: ${crp["lagna_sign_lord"] ?? "-"}'),
                          Text('လဂ်နက္ခတ်: ${crp["lagna_star_lord"] ?? "-"}'),
                          Text('စန်းရာသီ: ${crp["moon_sign_lord"] ?? "-"}'),
                          Text('စန်းနက္ခတ်: ${crp["moon_star_lord"] ?? "-"}'),
                          Text('နေ့နံ: ${crp["day_lord"] ?? "-"}'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 25),

            const Text('ဘာဝအကျိုးဆောင် ဇယား (KP Significators)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xFF27AE60)),
                headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                border: TableBorder.all(color: Colors.grey.shade300),
                columns: const [
                  DataColumn(label: Text('ဂြိုဟ်')),
                  DataColumn(label: Text('Level 1')),
                  DataColumn(label: Text('Level 2')),
                  DataColumn(label: Text('Level 3')),
                  DataColumn(label: Text('Level 4')),
                  DataColumn(label: Text('အကျိုးပေးမည့် ဘာဝ')),
                ],
                rows: List.generate(resultData['planets']?.length ?? 0, (index) {
                  var p = resultData['planets'][index];
                  return DataRow(cells: [
                    DataCell(Text(p['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                    DataCell(Text(p['L1']?.isEmpty ?? true ? "-" : p['L1'].join(", "))),
                    DataCell(Text(p['L2']?.isEmpty ?? true ? "-" : p['L2'].join(", "))),
                    DataCell(Text(p['L3']?.isEmpty ?? true ? "-" : p['L3'].join(", "))),
                    DataCell(Text(p['L4']?.isEmpty ?? true ? "-" : p['L4'].join(", "))),
                    DataCell(Text(p['all_sig']?.join(", ") ?? "-", style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold))),
                  ]);
                }),
              ),
            ),
            const SizedBox(height: 25),

            if (dashas.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ဝိံသောတ္တရီ ဒသာ (Vimshottari Dasha)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade300, width: 2)),
                    child: Column(
                      children: dashas.map<Widget>((d) {
                        if (d is Map) {
                          String lord = d['lord'] ?? '';
                          String start = d['start'] ?? '';
                          String end = d['end'] ?? '';
                          bool isActive = d['is_active'] == true;
                          List ads = d['ads'] ?? [];

                          return ExpansionTile(
                            title: Text('⭐ $lord မဟာဒသာ ($start မှ $end)', style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.deepOrange : Colors.black87)),
                            children: ads.map<Widget>((ad) {
                              String adLord = ad['lord'] ?? '';
                              String adStart = ad['start'] ?? '';
                              String adEnd = ad['end'] ?? '';
                              bool adActive = ad['is_active'] == true;
                              return ListTile(
                                contentPadding: const EdgeInsets.only(left: 40, right: 15),
                                title: Text('🔹 $adLord ဘုတ္တိ ($adStart မှ $adEnd)', style: TextStyle(color: adActive ? Colors.deepOrange : Colors.black54, fontWeight: adActive ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                              );
                            }).toList(),
                          );
                        }
                        return const SizedBox();
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),

            if (pData != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: const Color(0xFFE8F8F5), borderRadius: BorderRadius.circular(8), border: const Border(left: BorderSide(color: Color(0xFF1ABC9C), width: 5))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔮 ${pData["title"] ?? "ဒသာအဟော"}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16A085))),
                    const SizedBox(height: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFD1F2EB), borderRadius: BorderRadius.circular(12)), child: Text('📅 ${pData["start"]} မှ ${pData["end"]} အထိ', style: const TextStyle(color: Color(0xFF0E6655), fontSize: 13))),
                    const SizedBox(height: 10),
                    Text('ပေါင်းစပ် အကျိုးပေးမည့် ဘာဝများ: ${pData["combined_sigs"]?.join(", ") ?? "-"}', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (pData["preds"] != null)
                      ...List.generate(pData["preds"].length, (index) {
                        return Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('📌 ${pData["preds"][index]}', style: const TextStyle(height: 1.5)));
                      }),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            if (daily.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: const Color(0xFFEAF2F8), borderRadius: BorderRadius.circular(8), border: const Border(left: BorderSide(color: Color(0xFF3498DB), width: 5))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌙 ယခုလက်ရှိ စန်း (လ) ဖြတ်သန်းမှု အဟော', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2980B9))),
                    const SizedBox(height: 10),
                    Text('စန်းရပ်ရာသီ: ${daily["sign"] ?? "-"}  |  နက္ခတ်သခင်: ${daily["star_lord"] ?? "-"}'),
                    const SizedBox(height: 10),
                    if (daily["preds"] != null)
                      ...List.generate(daily["preds"].length, (index) {
                        return Text('• ${daily["preds"][index].replaceAll(RegExp(r'<[^>]*>'), '')}', style: const TextStyle(height: 1.5));
                      }),
                  ],
                ),
              ),
            const SizedBox(height: 80), // ခလုတ်နှင့် မထပ်စေရန် နေရာချန်ထားခြင်း
          ],
        ),
      ),
    );
  }
}