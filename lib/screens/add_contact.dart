import 'dart:collection';
import 'dart:convert';

import 'package:cryptowallet/main.dart';
import 'package:cryptowallet/screens/enter_contact_address.dart';
import 'package:cryptowallet/utils/rpc_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:hive/hive.dart';

import '../interface/coin.dart';
import '../utils/app_config.dart';

class AddContact extends StatefulWidget {
  final Map dataMap;
  final String name;
  const AddContact({Key key, this.dataMap, this.name}) : super(key: key);

  @override
  State<AddContact> createState() => _AddContactState();
}

class _AddContactState extends State<AddContact> {
  final nameController = TextEditingController();
  Map<dynamic, dynamic> addressDataMap;

  @override
  void initState() {
    super.initState();
    addressDataMap = widget.dataMap ?? {};
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<bool> _deleteContact(String key) async {
    addressDataMap.remove(key);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    addressDataMap = SplayTreeMap<String, dynamic>.from(
      addressDataMap,
      (a, b) => a.compareTo(b),
    );

    return WillPopScope(
      onWillPop: () async {
        bool willPop = false;
        await showDialogWithMessage(
          context: context,
          btnCancelColor: Colors.blue,
          btnOkColor: Colors.red[400],
          message: AppLocalizations.of(context).confirmClose,
          onConfirm: () {
            willPop = true;
          },
          onCancel: () {
            willPop = true;
          },
        );

        return willPop;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context).add_contact,
          ),
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
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController..text = widget.name,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).name,
                        focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                            borderSide: BorderSide.none),
                        border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                            borderSide: BorderSide.none),
                        enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                            borderSide: BorderSide.none), // you
                        filled: true,
                      ),
                    ),
                    if (addressDataMap.isNotEmpty)
                      const SizedBox(
                        height: 20,
                      ),
                    ...[
                      for (String key in addressDataMap.keys) ...[
                        Dismissible(
                            onDismissed: (DismissDirection direction) {
                              setState(() {});
                            },
                            direction: DismissDirection.endToStart,
                            key: UniqueKey(),
                            confirmDismiss: (DismissDirection direction) async {
                              return await _deleteContact(key);
                            },
                            secondaryBackground: Container(
                              color: Colors.red,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              alignment: Alignment.centerRight,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            background: Container(
                              color: Colors.blue,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              alignment: Alignment.centerLeft,
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    Coin blockChain =
                                        getAllBlockchains.firstWhere(
                                      (element) => (element.name_() == key),
                                    );

                                    Map addressData = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (ctx) => EnterContactAddress(
                                          tokenData: blockChain,
                                          recipient: addressDataMap[key]
                                              ['address'],
                                        ),
                                      ),
                                    );
                                    if (addressData == null) return;
                                    addressDataMap.remove(addressData['name']);

                                    addressDataMap.addAll(
                                      Map<String, dynamic>.from(
                                        {
                                          addressData['name']: addressData,
                                        },
                                      ),
                                    );
                                    setState(() {});
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundImage: AssetImage(
                                            addressDataMap[key]['image'],
                                          ),
                                          backgroundColor:
                                              Theme.of(context).backgroundColor,
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              addressDataMap[key]['name'],
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              ellipsify(
                                                str: addressDataMap[key]
                                                    ['address'],
                                                maxLength: 26,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.blueGrey,
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider()
                              ],
                            )),
                      ]
                    ],
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      color: Colors.transparent,
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith(
                              (states) => appBackgroundblue),
                          shape: MaterialStateProperty.resolveWith(
                            (states) => RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          textStyle: MaterialStateProperty.resolveWith(
                            (states) => const TextStyle(color: Colors.white),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).add_address,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          addAddressBlockchain(
                            context: context,
                            excludeBlockchains: addressDataMap,
                            onTap: (blockChainData) async {
                              Navigator.pop(context);
                              Map<dynamic, dynamic> addressData =
                                  await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => EnterContactAddress(
                                    tokenData: blockChainData,
                                  ),
                                ),
                              );

                              if (addressData == null) return;

                              addressData.removeWhere((key, value) {
                                try {
                                  json.encode(value);
                                  return false;
                                } catch (_) {
                                  return true;
                                }
                              });
                              addressDataMap.addAll(
                                Map<String, dynamic>.from(
                                  {
                                    addressData['name']: addressData,
                                  },
                                ),
                              );
                              setState(() {});
                            },
                            blockchainName: null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      color: Colors.transparent,
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith(
                              (states) => appBackgroundblue),
                          shape: MaterialStateProperty.resolveWith(
                            (states) => RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          textStyle: MaterialStateProperty.resolveWith(
                            (states) => const TextStyle(color: Colors.white),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).save,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          final name = nameController.text.trim();
                          if (name == "") {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(
                                  AppLocalizations.of(context).enterName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                            return;
                          }
                          final savedData = {
                            'name': name,
                            'dataList': addressDataMap
                          };

                          List addedContacts = [];
                          if (pref.get(addcontactKey) != null) {
                            addedContacts =
                                jsonDecode(pref.get(addcontactKey)) as List;

                            for (int i = 0; i < addedContacts.length; i++) {
                              if (addedContacts[i]['name'] == name) {
                                addedContacts.removeAt(i);
                              }
                            }
                          }

                          addedContacts.add(savedData);

                          await pref.put(
                            addcontactKey,
                            json.encode(addedContacts),
                          );

                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
