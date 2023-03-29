import 'dart:convert';

import 'package:cryptowallet/screens/add_contact.dart';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';

import '../utils/app_config.dart';

class Contact extends StatefulWidget {
  final bool showAdd;
  final String sendName;
  const Contact({
    Key key,
    this.showAdd,
    this.sendName,
  }) : super(key: key);

  @override
  State<Contact> createState() => _ContactState();
}

class _ContactState extends State<Contact> {
  final pref = Hive.box(secureStorageKey);
  List contacts = [];
  List languages;
  String languageCode;
  refreshContacts() {
    String jsonData = pref.get(addcontactKey);
    if (jsonData != null) {
      contacts = jsonDecode(jsonData);
      contacts.sort(
        (a, b) => a['name'].compareTo(b['name']),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    refreshContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).contact,
        ),
        actions: [
          if (widget.showAdd ?? true)
            IconButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const AddContact(),
                    ),
                  );
                  refreshContacts();
                  setState(() {});
                },
                icon: const Icon(FontAwesomeIcons.plus)),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 2));
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (contacts.isEmpty)
                        const Text(
                          'No Contact Yet',
                          style: TextStyle(fontSize: 18),
                        )
                      else
                        for (int i = 0; i < contacts.length; i++) ...[
                          GestureDetector(
                            onTap: () async {
                              if (widget.showAdd ?? true) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => AddContact(
                                      dataMap: contacts[i]['dataList'],
                                      name: contacts[i]['name'],
                                    ),
                                  ),
                                );
                                refreshContacts();
                                setState(() {});
                              } else {
                                Map dataList = contacts[i]['dataList'];
                                if (dataList[widget.sendName] == null) {
                                  Navigator.pop(context);
                                  return;
                                }

                                Navigator.pop(
                                  context,
                                  dataList[widget.sendName]['address'],
                                );
                              }
                            },
                            child: Container(
                              color: Colors.transparent,
                              width: double.infinity,
                              height: 35,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    contacts[i]['name'],
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey,
                                  )
                                ],
                              ),
                            ),
                          ),
                          if (i != contacts.length - 1) const Divider()
                        ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
