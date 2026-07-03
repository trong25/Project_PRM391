import 'package:flutter/material.dart';
import '../../services/discount_service.dart';



class VoucherScreen extends StatefulWidget {


  const VoucherScreen({super.key});


  @override
  State<VoucherScreen> createState()
  => _VoucherScreenState();


}



class _VoucherScreenState
    extends State<VoucherScreen>{



  final service = DiscountService();


  List vouchers=[];



  @override
  void initState(){

    super.initState();

    loadData();

  }



  void loadData() async{


    final data =
    await service.getDiscounts();


    setState((){

      vouchers=data;

    });


  }




  void deleteVoucher(int id) async{


    await service.deleteDiscount(id);


    loadData();


  }





  @override
  Widget build(BuildContext context){


    return Scaffold(


      floatingActionButton: FloatingActionButton(
        child:const Icon(Icons.add),

        onPressed:(){

// mở form thêm

        },

      ),



      body:ListView.builder(

        itemCount:vouchers.length,


        itemBuilder:(context,index){


          final v=vouchers[index];


          return Card(

            child:ListTile(

              title:Text(
                  v['code']
              ),


              subtitle:Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children:[


                  Text(
                      v['description']??''
                  ),


                  Text(
                      "Giảm ${v['discountValue']}"
                  ),


                  Text(
                      v['status']
                  )


                ],

              ),



              trailing:Row(

                mainAxisSize:
                MainAxisSize.min,


                children:[


                  IconButton(

                    icon:
                    const Icon(Icons.edit),

                    onPressed:(){

// sửa

                    },

                  ),

                  IconButton(

                    icon:
                    const Icon(Icons.delete),

                    onPressed:(){

                      deleteVoucher(
                          v['discountId']
                      );

                    },

                  )



                ],

              ),


            ),


          );


        },



      ),



    );


  }



}