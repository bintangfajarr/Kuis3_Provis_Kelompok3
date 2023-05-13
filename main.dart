import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';

// sebaiknya di file terpisah
// menampung data hasil pemanggilan API
class Pinjaman {
  String nama;
  String id;

  Pinjaman({required this.nama, required this.id});
}

class Detail {
  String id;
  String nama;
  String bunga;
  String is_syariah;

  Detail(
      {required this.id,
      required this.nama,
      required this.bunga,
      required this.is_syariah});
}

class DetailCubit extends Cubit<Detail> {
  String url = "http://178.128.17.76:8000/detil_jenis_pinjaman/";
  int id = 1;
  DetailCubit() : super(Detail(id: "", nama: "", bunga: "", is_syariah: ""));

  //map dari json ke atribut
  void setFromJson(Map<String, dynamic> json) {
    String id = json['id'];
    String nama = json['nama'];
    String bunga = json['bunga'];
    String is_syariah = json['is_syariah'];

    emit(Detail(id: id, nama: nama, bunga: bunga, is_syariah: is_syariah));
  }

  void fetchData() async {
    if (id >= 1) {
      id += 1;
    } else if (id == 3) {
      id = 1;
    }
    final response = await http.get(Uri.parse(url + id.toString()));
    if (response.statusCode == 200) {
      setFromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal load');
    }
  }
}

class ListPinjaman {
  //list berisi nama dan situs
  List<Pinjaman> listPinjaman = <Pinjaman>[];

  //constructor
  ListPinjaman(dynamic json) {
    //loop isi elemen data untuk ambil nama dan situs
    var data = json["data"];
    for (var val in data) {
      var nama = val['nama'].toString();
      var id = val['id'].toString();
      //tambahkan ke array
      listPinjaman.add(Pinjaman(nama: nama, id: id));
    }
  }

  //map dari json ke atribut
  factory ListPinjaman.fromJson(dynamic json) {
    return ListPinjaman(json);
  }
}

class ListPinjamCubit extends Cubit<ListPinjaman> {
  bool loading = true;
  String id = "1";
  String url = "http://178.128.17.76:8000/jenis_pinjaman/";

  //constructor
  ListPinjamCubit() : super(ListPinjaman([])) {
    fetchData();
  }

  //map dari json ke atribut
  void setFromJson(dynamic json) {
    emit(ListPinjaman(json));
  }

  void fetchData() async {
    final response = await http.get(Uri.parse(url + id));
    if (response.statusCode == 200) {
      if (loading) loading = false;
      setFromJson(jsonDecode(response.body));
    } else {
      if (loading) loading = false;
      throw Exception('Gagal load');
    }
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ListPinjamCubit()),
        BlocProvider(create: (context) => DetailCubit()),
      ],
      child: MaterialApp(home: HalamanUtama()),
    );
  }
}

class HalamanUtama extends StatefulWidget {
  const HalamanUtama({Key? key}) : super(key: key);

  @override
  HalamanUtamaState createState() => HalamanUtamaState();
}

class HalamanUtamaState extends State<HalamanUtama> {
  List<String> pinjamanList = ["1", "2", "3"];
  String selectedID = "1";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Kuis 3',
        home: Scaffold(
            appBar: AppBar(
              title: const Text('My App P2P'),
            ),
            body: Column(children: [
              Text(
                  "2102313, Muhammad Kamal Robbani; 2102665, Muhammad Cahyana Bintang Fajar; Saya berjanji tidak akan berbuat curang data atau membantu orang lain berbuat curang"),
              BlocBuilder<DetailCubit, Detail>(
                builder: (context, aktivitas) {
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<DetailCubit>().fetchData();
                            },
                            child: const Text("Tampilkan Detil"),
                          ),
                        ),
                        Text("ID : " + aktivitas.id),
                        Text("Nama : " + aktivitas.nama),
                        Text("Bunga : " + aktivitas.bunga),
                        Text("Syariah : " + aktivitas.is_syariah),
                      ]));
                },
              ),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedID,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedID = newValue!;
                  });
                  // access the ListUnivCubit instance
                  final listPinjamCubit =
                      BlocProvider.of<ListPinjamCubit>(context);
                  // BlocProvider.of<ListUnivCubit>(context).loading = true;
                  // BlocProvider.of<ListUnivCubit>(context).negara = newValue!;
                  // BlocProvider.of<ListUnivCubit>(context).fetchData();
                  listPinjamCubit.loading = true;
                  listPinjamCubit.id = newValue!;
                  listPinjamCubit
                      .fetchData(); // sama dengan context.read<ListUnivCubit>().fetchData();
                },
                items: pinjamanList.map((id) {
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Center(child: Text("Jenis Pinjaman " + id)),
                  );
                }).toList(),
              ),
              Expanded(
                  child: BlocBuilder<ListPinjamCubit, ListPinjaman>(
                      buildWhen: (previousState, state) {
                return true;
              }, builder: (context, pinjam) {
                final listPinjamCubit =
                    BlocProvider.of<ListPinjamCubit>(context);
                if (listPinjamCubit.loading) {
                  // return const CircularProgressIndicator();
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (pinjam.listPinjaman.isNotEmpty) {
                  // gunakan listview builder
                  return ListView.builder(
                      itemCount: pinjam.listPinjaman.length,
                      itemBuilder: (context, index) {
                        return Container(
                            decoration: BoxDecoration(border: Border.all()),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(pinjam.listPinjaman[index].nama),
                                  Text(pinjam.listPinjaman[index].id),
                                ]));
                      });
                } else {
                  return Text('List pinjaman tidak ada.');
                }
              }))
            ])));
  }
}
