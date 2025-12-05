import 'package:flutter/material.dart';
import 'package:sri_master/screens/file_Screen.dart';
import 'package:sri_master/screens/tabs_sri/tab_anulados.dart';
import 'package:sri_master/screens/tabs_sri/tab_xmls.dart';

class Sri_tabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: DefaultTabController(
        length: 2, // Replace 3 with the number of tabs you want
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Descargar XMLs'),
                Tab(text: 'Anulados'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Container(
                    child: Center(
                      child: xmls_screen(),
                    ),
                  ),
                  // Replace these with your tab views
                  Container(
                    child: Center(
                      child: DirectoryScreen(
                          directory: 'server/0990497214001_2023_Julio',
                          key: Key('directory_screen')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
