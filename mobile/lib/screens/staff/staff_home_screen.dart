// lib/screens/staff/staff_home_screen.dart

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import 'voucher_screen.dart';

class StaffHomeScreen extends StatefulWidget {

  const StaffHomeScreen({super.key});


  @override
  State<StaffHomeScreen> createState() =>
      _StaffHomeScreenState();

}



class _StaffHomeScreenState
    extends State<StaffHomeScreen> {


  int _currentIndex = 0;



  final List<String> _titles = [

    "Đặt phòng",
    "Phòng",
    "Voucher",
    "Feedback"

  ];
  final List<Widget> pages=[

    Center(
      child:Text("Đặt phòng"),
    ),


    Center(
      child:Text("Phòng"),
    ),


    const VoucherScreen(),


    Center(
      child:Text("Feedback"),
    ),


  ];


  final List<IconData> _icons = [

    Icons.calendar_month,
    Icons.hotel,
    Icons.confirmation_number,
    Icons.feedback,

  ];




  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(

        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: AppTheme.primary,

        foregroundColor: Colors.white,

      ),



      body: Center(

        child: Column(

          mainAxisAlignment:
          MainAxisAlignment.center,


          children: [


            Icon(

              _icons[_currentIndex],

              size: 80,

              color: AppTheme.primary,

            ),



            const SizedBox(height:20),



            Text(

              _titles[_currentIndex],

              style: const TextStyle(

                fontSize:24,

                fontWeight:FontWeight.bold,

              ),

            ),



            const SizedBox(height:10),



            const Text(

              "Chức năng đang phát triển",

              style: TextStyle(

                color: Colors.grey,

                fontSize:16,

              ),

            ),


          ],

        ),

      ),




      bottomNavigationBar:


      BottomNavigationBar(


        currentIndex: _currentIndex,


        selectedItemColor:
        AppTheme.primary,


        unselectedItemColor:
        Colors.grey,


        type:
        BottomNavigationBarType.fixed,


        onTap:(index){


          setState(() {


            _currentIndex=index;


          });


        },



        items:[


          BottomNavigationBarItem(

            icon:
            Icon(_icons[0]),

            label:_titles[0],

          ),



          BottomNavigationBarItem(

            icon:
            Icon(_icons[1]),

            label:_titles[1],

          ),



          BottomNavigationBarItem(

            icon:
            Icon(_icons[2]),

            label:_titles[2],

          ),



          BottomNavigationBarItem(

            icon:
            Icon(_icons[3]),

            label:_titles[3],

          ),



        ],


      ),


    );


  }


}