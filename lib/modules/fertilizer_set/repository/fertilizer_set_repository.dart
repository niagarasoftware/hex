import 'package:http/http.dart' as http;
import 'package:hex/services/http_service.dart';

class FertilizerSetRepository{
  HttpService httpService = HttpService();

  Future<http.Response> getUserFertilizerSet(body) async {
    return await httpService.postRequest('/user/planning/fertilizerSet/get', body);
  }

  Future<http.Response> createUserFertilizerSet(body) async {
    return await httpService.postRequest('/user/planning/fertilizerSet/create', body);
  }

}