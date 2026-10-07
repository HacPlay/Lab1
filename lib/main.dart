import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorSalariuApp());
}

class CalculatorSalariuApp extends StatelessWidget {
  const CalculatorSalariuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator salariu net',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const EcranCalculator(),
    );
  }
}

// ---------- Modele ----------

/// Regim de impozitare (țara ale cărei cote se aplică).
enum RegimImpozitare { moldova, romania }

extension RegimImpozitareLabel on RegimImpozitare {
  String get label {
    switch (this) {
      case RegimImpozitare.moldova:
        return 'Republica Moldova';
      case RegimImpozitare.romania:
        return 'România';
    }
  }
}

/// Tip de angajat, în funcție de scutirea personală acordată.
enum TipAngajat { cuScutire, faraScutire }

extension TipAngajatLabel on TipAngajat {
  String get label {
    switch (this) {
      case TipAngajat.cuScutire:
        return 'Cu scutire personală (2.475 lei)';
      case TipAngajat.faraScutire:
        return 'Fără scutire personală';
    }
  }

  double get scutireLunara => this == TipAngajat.cuScutire ? 2475.0 : 0.0;
}

/// Rezultatul calculului: salariul net și detalierea reținerilor.
class RezultatCalcul {
  final double salariuNet;
  final double contributie1; // CAM (Moldova) sau CAS (România)
  final double contributie2; // 0 (Moldova) sau CASS (România)
  final double impozitVenit;

  RezultatCalcul({
    required this.salariuNet,
    required this.contributie1,
    required this.contributie2,
    required this.impozitVenit,
  });

  double get totalRetinut => contributie1 + contributie2 + impozitVenit;
}

// ---------- Logica de calcul ----------

class CalculatorSalariu {
  static RezultatCalcul calculeaza(
      double brut,
      RegimImpozitare regim,
      TipAngajat tip,
      ) {
    if (regim == RegimImpozitare.moldova) {
      // 1) CAM - asigurarea medicală obligatorie: 9% din brut
      final cam = brut * 0.09;
      // 2) Baza impozabilă = brut - CAM - scutire personală
      final bazaImpozabila = (brut - cam - tip.scutireLunara).clamp(0, double.infinity);
      // 3) Impozitul pe venit: 12% din baza impozabilă
      final impozit = bazaImpozabila * 0.12;
      final net = brut - cam - impozit;
      return RezultatCalcul(
        salariuNet: net,
        contributie1: cam,
        contributie2: 0,
        impozitVenit: impozit,
      );
    } else {
      // 1) CAS - asigurări sociale (pensii): 25% din brut
      final cas = brut * 0.25;
      // 2) CASS - asigurări sociale de sănătate: 10% din brut
      final cass = brut * 0.10;
      // 3) Baza impozabilă = brut - CAS - CASS - deducere personală (dacă e cazul)
      final bazaImpozabila =
      (brut - cas - cass - tip.scutireLunara).clamp(0, double.infinity);
      // 4) Impozitul pe venit: 10% din baza impozabilă
      final impozit = bazaImpozabila * 0.10;
      final net = brut - cas - cass - impozit;
      return RezultatCalcul(
        salariuNet: net,
        contributie1: cas,
        contributie2: cass,
        impozitVenit: impozit,
      );
    }
  }
}

// ---------- UI ----------

class EcranCalculator extends StatefulWidget {
  const EcranCalculator({super.key});

  @override
  State<EcranCalculator> createState() => _EcranCalculatorState();
}

class _EcranCalculatorState extends State<EcranCalculator> {
  final TextEditingController _controllerBrut = TextEditingController();

  RegimImpozitare _regimSelectat = RegimImpozitare.moldova;
  TipAngajat _tipSelectat = TipAngajat.cuScutire;

  RezultatCalcul? _rezultat;
  String? _eroare;

  String _formateaza(double v) => v.toStringAsFixed(2);

  void _calculeaza() {
    final text = _controllerBrut.text.trim().replaceAll(',', '.');
    final brut = double.tryParse(text);

    setState(() {
      if (brut == null || brut <= 0) {
        _eroare = 'Introduceți un salariu brut valid (număr pozitiv).';
        _rezultat = null;
      } else {
        _eroare = null;
        _rezultat = CalculatorSalariu.calculeaza(brut, _regimSelectat, _tipSelectat);
      }
    });
  }

  @override
  void dispose() {
    _controllerBrut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculator salariu net')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ----- Input: salariul brut -----
            TextField(
              controller: _controllerBrut,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Salariul brut (lei)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // ----- DropdownButton: regim de impozitare -----
            const Text('Regim de impozitare', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<RegimImpozitare>(
              isExpanded: true,
              value: _regimSelectat,
              items: RegimImpozitare.values.map((regim) {
                return DropdownMenuItem(
                  value: regim,
                  child: Text(regim.label),
                );
              }).toList(),
              onChanged: (regim) {
                if (regim != null) {
                  setState(() => _regimSelectat = regim);
                }
              },
            ),
            const SizedBox(height: 20),

            // ----- RadioButton: tipul de angajat -----
            const Text('Tip de angajat', style: TextStyle(fontWeight: FontWeight.bold)),
            ...TipAngajat.values.map((tip) {
              return RadioListTile<TipAngajat>(
                contentPadding: EdgeInsets.zero,
                title: Text(tip.label),
                value: tip,
                groupValue: _tipSelectat,
                onChanged: (valoare) {
                  if (valoare != null) {
                    setState(() => _tipSelectat = valoare);
                  }
                },
              );
            }),
            const SizedBox(height: 12),

            // ----- ElevatedButton: declanșează calculul -----
            ElevatedButton(
              onPressed: _calculeaza,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Calculează'),
              ),
            ),

            if (_eroare != null) ...[
              const SizedBox(height: 12),
              Text(_eroare!, style: const TextStyle(color: Colors.red)),
            ],

            // ----- Output: salariul net + impozitele -----
            if (_rezultat != null) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salariul net: ${_formateaza(_rezultat!.salariuNet)} lei',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_regimSelectat == RegimImpozitare.moldova)
                        Text('CAM (asigurare medicală, 9%): ${_formateaza(_rezultat!.contributie1)} lei')
                      else ...[
                        Text('CAS (pensii, 25%): ${_formateaza(_rezultat!.contributie1)} lei'),
                        Text('CASS (sănătate, 10%): ${_formateaza(_rezultat!.contributie2)} lei'),
                      ],
                      Text('Impozit pe venit: ${_formateaza(_rezultat!.impozitVenit)} lei'),
                      const SizedBox(height: 4),
                      Text(
                        'Total reținut: ${_formateaza(_rezultat!.totalRetinut)} lei',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}