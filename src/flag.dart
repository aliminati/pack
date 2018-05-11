class flag {
  List<String> param;

  getAll() {
    var output = new Map();

    for (var item in param) {
      item = item.replaceAll('--', '');
      if (item.contains('=')) {
        var _pt = item.split('='); // pecah string
        output[_pt[0]] = _pt[1];
      } else {
        output[item] = item;
      }
      // print(item);
    }
    return output;
  }

  get(String nama) {
    var output = '';
    var args = getAll();
    if (args.containsKey(nama))
      output = args[nama];
    return output;
  }


  getWithDefault(String nama, String standar) {
    var output;
    var val = get(nama);
    if (val.length > 0) {
      if (val == nama)
        output = standar;
      else
        output = val;
    } else {
      output = standar;
    }
    return output;
  }
    
}