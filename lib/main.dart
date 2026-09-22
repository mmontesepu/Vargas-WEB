import 'dart:convert';
import 'package:flutter/material.dart';
import 'app/theme/app_theme.dart';
import 'features/quotes/models/quote.dart';
import 'features/quotes/models/quote_item.dart';
import 'features/quotes/services/quote_pdf_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

String money(num value) =>
    '\$${value.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

void main() => runApp(const VargasApp());

class VargasApp extends StatelessWidget {
  const VargasApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Vargas SPA Construcciones',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomePage(),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            backgroundColor: ink,
            title: const Text('VARGAS.SPA',
                style:
                    TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminPage())),
                  child: const Text('Administración'))
            ]),
        body: SingleChildScrollView(
            child: Column(children: [
          Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 560),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 72),
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF0E1012), Color(0xFF332015)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)),
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1050),
                      child: Wrap(
                          spacing: 55,
                          runSpacing: 30,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                                width: 520,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('CONSTRUIMOS CON PROPÓSITO',
                                          style: TextStyle(
                                              color: gold,
                                              letterSpacing: 3,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 20),
                                      const Text('Espacios que dejan huella.',
                                          style: TextStyle(
                                              fontSize: 56,
                                              height: 1.08,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 20),
                                      const Text(
                                          'Proyectos de construcción y remodelación con atención a cada detalle.',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white70)),
                                      const SizedBox(height: 30),
                                      FilledButton(
                                          onPressed: () => _contact(context),
                                          child: const Text(
                                              'Solicitar cotización')),
                                    ])),
                            Image.asset('assets/images/logo.png',
                                width: 330, fit: BoxFit.contain),
                          ])))),
          const Padding(
              padding: EdgeInsets.fromLTRB(24, 72, 24, 18),
              child: Text('Lo que hacemos',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold))),
          Padding(
              padding: const EdgeInsets.all(24),
              child: Wrap(spacing: 20, runSpacing: 20, children: [
                for (final item in [
                  ('Construcción', Icons.apartment),
                  ('Remodelaciones', Icons.construction),
                  ('Terminaciones', Icons.handyman)
                ])
                  Container(
                      width: 290,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                          color: panel,
                          borderRadius: BorderRadius.circular(18)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(item.$2, color: gold, size: 38),
                            const SizedBox(height: 24),
                            Text(item.$1,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold))
                          ])),
              ])),
          const SizedBox(height: 45),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(35),
              color: panel,
              child: const Center(
                  child: Text('VARGAS.SPA  •  CONSTRUCCIONES',
                      style: TextStyle(letterSpacing: 2, color: gold)))),
        ])),
      );
  void _contact(BuildContext context) => showDialog(
      context: context,
      builder: (_) => AlertDialog(
              title: const Text('Solicitar cotización'),
              content: const Text(
                  'Próximamente conectaremos el formulario de contacto. La sección de cotizaciones ya está disponible para el administrador.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'))
              ]));
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Quote> quotes = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      quotes = (jsonDecode(prefs.getString('quotes') ?? '[]') as List)
          .map((e) => Quote.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      quotes = [];
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'quotes', jsonEncode(quotes.map((e) => e.toJson()).toList()));
  }

  Future<void> _edit([Quote? existing]) async {
    final result = await Navigator.push<Quote>(
        context,
        MaterialPageRoute(
            builder: (_) => QuoteEditor(
                existing: existing, nextNumber: quotes.length + 1)));
    if (result == null) return;
    setState(() {
      final i = quotes.indexWhere((q) => q.id == result.id);
      if (i < 0) {
        quotes.insert(0, result);
      } else {
        quotes[i] = result;
      }
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('VARGAS.SPA  /  Administración'),
            backgroundColor: ink,
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver al sitio'))
            ]),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1150),
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cotizaciones',
                              style: TextStyle(
                                  fontSize: 36, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          const Text(
                              'Gestiona tus propuestas y genera documentos para tus clientes.',
                              style: TextStyle(color: Colors.white60)),
                          const SizedBox(height: 28),
                          Wrap(spacing: 15, runSpacing: 15, children: [
                            for (final x in [
                              ('Cotizaciones', '${quotes.length}'),
                              (
                                'Total cotizado',
                                money(quotes.fold<double>(
                                    0, (s, q) => s + q.total))
                              )
                            ])
                              Container(
                                  width: 250,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                      color: panel,
                                      borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(x.$1,
                                            style: const TextStyle(
                                                color: Colors.white60)),
                                        const SizedBox(height: 8),
                                        Text(x.$2,
                                            style: const TextStyle(
                                                color: gold,
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold))
                                      ]))
                          ]),
                          const SizedBox(height: 28),
                          FilledButton.icon(
                              onPressed: () => _edit(),
                              icon: const Icon(Icons.add),
                              label: const Text('Nueva cotización')),
                          const SizedBox(height: 20),
                          Expanded(
                              child: loading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : quotes.isEmpty
                                      ? const Center(
                                          child: Text(
                                              'Crea tu primera cotización.'))
                                      : ListView.separated(
                                          itemCount: quotes.length,
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(height: 10),
                                          itemBuilder: (_, i) {
                                            final q = quotes[i];
                                            return Card(
                                                child: ListTile(
                                                    contentPadding:
                                                        const EdgeInsets.all(
                                                            14),
                                                    title: Text(
                                                        '${q.id}  •  ${q.client}'),
                                                    subtitle: Text(
                                                        '${q.status}  ·  ${q.date.day}/${q.date.month}/${q.date.year}'),
                                                    trailing: Wrap(
                                                        crossAxisAlignment:
                                                            WrapCrossAlignment
                                                                .center,
                                                        children: [
                                                          Text(money(q.total),
                                                              style: const TextStyle(
                                                                  color: gold,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          IconButton(
                                                              tooltip: 'PDF',
                                                              onPressed: () =>
                                                                  QuotePdfService
                                                                      .generate(
                                                                          q),
                                                              icon: const Icon(Icons
                                                                  .picture_as_pdf)),
                                                          IconButton(
                                                              tooltip: 'Editar',
                                                              onPressed: () =>
                                                                  _edit(q),
                                                              icon: const Icon(Icons
                                                                  .edit_outlined))
                                                        ])));
                                          })),
                        ])))),
      );
}

class QuoteEditor extends StatefulWidget {
  final Quote? existing;
  final int nextNumber;
  const QuoteEditor({super.key, this.existing, required this.nextNumber});
  @override
  State<QuoteEditor> createState() => _QuoteEditorState();
}

class _QuoteEditorState extends State<QuoteEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController client, email, address, notes, payment;
  late List<QuoteItem> items;
  late String status;
  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    client = TextEditingController(text: q?.client);
    email = TextEditingController(text: q?.email);
    address = TextEditingController(text: q?.address);
    notes = TextEditingController(text: q?.notes);
    payment = TextEditingController(text: q?.payment);
    items = q?.items
            .map((e) => QuoteItem(e.description, e.unit, e.quantity, e.price))
            .toList() ??
        [QuoteItem('', 'GL', 1, 0)];
    status = q?.status ?? 'Borrador';
  }

  @override
  void dispose() {
    for (final c in [client, email, address, notes, payment]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget field(String label, TextEditingController controller,
          {bool required = false}) =>
      TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          validator: required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null
              : null);
  @override
  Widget build(BuildContext context) {
    final net = items.fold<double>(0, (s, e) => s + e.total);
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.existing == null
                ? 'Nueva cotización'
                : 'Editar ${widget.existing!.id}'),
            backgroundColor: ink),
        body: Form(
            key: form,
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child:
                        ListView(padding: const EdgeInsets.all(24), children: [
                      const Text('Datos del cliente',
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 18),
                      field('Nombre o empresa *', client, required: true),
                      const SizedBox(height: 12),
                      field('Correo', email),
                      const SizedBox(height: 12),
                      field('Dirección de obra', address),
                      const SizedBox(height: 30),
                      const Text('Ítems',
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      ...items.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return Card(
                            key: ValueKey(item),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(children: [
                                  TextFormField(
                                      initialValue: item.description,
                                      decoration: const InputDecoration(
                                          labelText: 'Descripción *'),
                                      onChanged: (v) => item.description = v,
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Describe el ítem'
                                              : null),
                                  const SizedBox(height: 12),
                                  Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        SizedBox(
                                            width: 105,
                                            child:
                                                DropdownButtonFormField<String>(
                                                    initialValue: item.unit,
                                                    decoration:
                                                        const InputDecoration(
                                                            labelText:
                                                                'Unidad'),
                                                    items: [
                                                      'UN',
                                                      'M2',
                                                      'M3',
                                                      'ML',
                                                      'KG',
                                                      'GL'
                                                    ]
                                                        .map((e) =>
                                                            DropdownMenuItem(
                                                                value: e,
                                                                child: Text(e)))
                                                        .toList(),
                                                    onChanged: (v) => setState(
                                                        () => item.unit = v!))),
                                        SizedBox(
                                            width: 130,
                                            child: TextFormField(
                                                initialValue:
                                                    item.quantity.toString(),
                                                decoration:
                                                    const InputDecoration(
                                                        labelText: 'Cantidad'),
                                                keyboardType: const TextInputType
                                                    .numberWithOptions(
                                                    decimal: true),
                                                onChanged: (v) => setState(() =>
                                                    item.quantity =
                                                        double.tryParse(v.replaceAll(',', '.')) ??
                                                            0),
                                                validator: (_) =>
                                                    item.quantity <= 0
                                                        ? 'Debe ser > 0'
                                                        : null)),
                                        SizedBox(
                                            width: 160,
                                            child: TextFormField(
                                                initialValue: item.price
                                                    .toStringAsFixed(0),
                                                decoration:
                                                    const InputDecoration(
                                                        labelText:
                                                            'Precio unitario'),
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly
                                                ],
                                                onChanged: (v) => setState(() =>
                                                    item.price =
                                                        double.tryParse(v) ??
                                                            0),
                                                validator: (_) => item.price < 0
                                                    ? 'Precio inválido'
                                                    : null)),
                                        Text(money(item.total),
                                            style: const TextStyle(
                                                color: gold,
                                                fontWeight: FontWeight.bold)),
                                        IconButton(
                                            onPressed: items.length > 1
                                                ? () => setState(
                                                    () => items.removeAt(i))
                                                : null,
                                            icon: const Icon(
                                                Icons.delete_outline)),
                                      ]),
                                ])));
                      }),
                      TextButton.icon(
                          onPressed: () => setState(
                              () => items.add(QuoteItem('', 'GL', 1, 0))),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar ítem')),
                      const SizedBox(height: 20),
                      Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Neto: ${money(net)}'),
                                Text(
                                    'IVA (19%): ${money((net * .19).round())}'),
                                Text(
                                    'Total: ${money(net + (net * .19).round())}',
                                    style: const TextStyle(
                                        fontSize: 26,
                                        color: gold,
                                        fontWeight: FontWeight.bold))
                              ])),
                      const SizedBox(height: 25),
                      field('Forma de pago', payment),
                      const SizedBox(height: 12),
                      field('Observaciones', notes),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration:
                              const InputDecoration(labelText: 'Estado'),
                          items: [
                            'Borrador',
                            'Enviada',
                            'Aprobada',
                            'Rechazada'
                          ]
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => status = v!),
                      const SizedBox(height: 28),
                      FilledButton(
                          onPressed: () {
                            if (!form.currentState!.validate()) return;
                            final now = DateTime.now();
                            final id = widget.existing?.id ??
                                'COT-${now.year}-${widget.nextNumber.toString().padLeft(4, '0')}';
                            Navigator.pop(
                                context,
                                Quote(
                                    id,
                                    client.text.trim(),
                                    email.text.trim(),
                                    address.text.trim(),
                                    notes.text.trim(),
                                    payment.text.trim(),
                                    status,
                                    widget.existing?.date ?? now,
                                    items));
                          },
                          child: const Text('Guardar cotización')),
                      const SizedBox(height: 35),
                    ])))));
  }
}
