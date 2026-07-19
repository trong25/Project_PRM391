import 'package:dio/dio.dart';
import 'api_client.dart';


class DiscountService {


  final Dio _dio = ApiClient.instance.dio;



  Future<List<dynamic>> getDiscounts() async {

    final response =
    await _dio.get('/discount');

    return response.data;

  }




  Future<void> createDiscount(
      Map<String,dynamic> data
      ) async {


    await _dio.post(
      '/discount',
      data:data,
    );


  }




  Future<void> updateDiscount(
      int id,
      Map<String,dynamic> data
      ) async {


    await _dio.put(
        '/discount/$id',
        data:data
    );


  }





  Future<void> deleteDiscount(
      int id
      ) async {


    await _dio.delete(
        '/discount/$id'
    );


  }


}