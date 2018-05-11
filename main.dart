import 'dart:io';
import 'package:path/path.dart' as P;
import 'package:glob/glob.dart';
import 'package:watcher/watcher.dart';
import 'package:sass/sass.dart' as sass;
import 'package:colorize/colorize.dart';
import 'src/flag.dart';

bacaIsiFile(var file) {
    return new File(file).readAsStringSync();
}

balikKalimat(String param) {
  return new String.fromCharCodes(param.runes.toList().reversed);
}

getFileName(String path) {
  File file = new File(path);
  return P.basename(file.path);
}

getFileExt(String path){
  String fileName = getFileName(path).toString();
  String balikNama = balikKalimat(fileName);
  List pecahan = balikNama.split('.');
  return balikKalimat(pecahan[0]);
}

htmlFileChangedIsRoot(String path) {
  if (path.contains('src/html/part') == false
  && path.contains('src/html') == true
  )
    return true;
  else
    return false;
}

htmlGetPartFiles(String dir) {
  dir = '${dir}/html/part';
  final src_html_files 	  = new Glob("${dir}/*.html");
  var data = new Map();
  for	(var entry in src_html_files.listSync()) {
		var key = getFileName(entry.path.toString()).replaceAll('.html', '');
		data[key] = bacaIsiFile(entry.path.toString());
	}
  return data;
}

htmlGetRootFilesPath(String dir) {
  dir = '${dir}/html';
  final root_files 	  = new Glob("${dir}/*.html");
  var data = new List();
  for	(var entry in root_files.listSync()) {
    String path = entry.path.toString().replaceAll('\\', '/');
    data.add(path);
	}
  return data;
}

htmlFileChangedIsPart(String path) {
  if (path.contains('src/html/part'))
    return true;
  else
    return false;
}

htmlGenDistFile(String rootFile, var partFiles) {
  var distFile = rootFile.replaceAll('/src/html/', '/dist/');
  String isiDistFile = bacaIsiFile(rootFile);
  for (var key in partFiles.keys) {
    isiDistFile = isiDistFile.replaceAll("<!-- include(part/${key}.html) -->", partFiles[key]);
  }
  var updated_file = new File(distFile).writeAsString(isiDistFile);
  print(new Colorize("- update : ${distFile}").blue().bold());

}

/*
* param: dir = folder yang diwatch
         file = file yang berubah
*/

perubahan(String dir, String file){
  try {

    // cek jika file html berubah
    // src      berubah: baca semua part - ubah this saja
    // src/part berubah: baca semua part - ubah semua root
    
    if(getFileExt(file) == 'html') {
      // print('--ext: html');
      print(new Colorize("- ext    : html").lightRed().bold());

      var htmlParts = htmlGetPartFiles(dir);  
      if (htmlFileChangedIsRoot(file)) {
        // print('--is root: true');      
        print(new Colorize("- root   : yes").lightRed().bold());
        htmlGenDistFile(file, htmlParts);
      } 
      if (htmlFileChangedIsPart(file)) {
        print(new Colorize("- root   : no").lightRed().bold());
        // print('--is root: false');            
        for (var item in htmlGetRootFilesPath(dir)) {
          htmlGenDistFile(item, htmlParts);      }
      } 
    } else if(getFileExt(file) == 'scss'){
      // print('--ext: scss');
      print(new Colorize("- ext    : scss").lightRed().bold());
      var srcCssFile  = "${dir}/assets/css/main.scss";
      var mainCssFile = "${dir}/dist/".replaceAll("src/dist/","dist/assets/css/main.css");
      var cssData = sass.compile(srcCssFile);
      new File(mainCssFile).writeAsStringSync(cssData);
    }
  } catch(e) {
    print(e);
  }
  return true;
}

amatiFolder(var ws, var DIR) async {
  print(new Colorize("Watch: ${DIR}").green().bold());
	// print("Watch: ${DIR}");
	var watcher = new DirectoryWatcher(P.absolute( DIR ));
	watcher.events.listen((event){
		if (event.toString().substring(0,6) == 'modify') {
			var fileBerubah = P.absolute("${event.toString().substring(7)}".replaceAll("\\", "/"));

			var msg = "- modify : ${fileBerubah}";
      print(new Colorize("${msg}").lightRed().bold());
			perubahan(DIR, fileBerubah);
			pesanBc(ws, "refresh");
		}
	});
}


//-*
// Websocket function
//

pesanBc(WebSocket ws, String msg) {
	ws.add(msg);
	// print('bc: ${msg}');
  print(new Colorize("bc       : ${msg}").green().bold());

}

pesanMasuk(WebSocket ws, String msg) {
	var feedback = msg;
	pesanBc(ws, feedback); // siarkan pesan
	// print('inbox: ${msg}');
  print(new Colorize("inbox: ${msg}").green().bold());
}

startWebsocket(var HOST, var PORT, var DIR ) async {
	try {
		var server = await HttpServer.bind(HOST, PORT);
    // print('Menjalankan server ${HOST}:${PORT}');
    print(new Colorize("Menjalankan server= ${HOST}:${PORT}").lightGreen().bold());
    print(new Colorize("folder= ${DIR}").lightGreen().bold());
		await for(HttpRequest req in server) {
			var ws = await WebSocketTransformer.upgrade(req);
			pesanBc(ws, "Client baru tersambung");
			var folderSrc = "${DIR}/src";
			amatiFolder(ws, folderSrc);
		}

	} catch(e) {
		print(e);
	}
}

main(List<String> args) {
  var argumen = new flag()
      ..param = args;

  var DIR   = argumen.getWithDefault('dir', 'D:/project/office/an-final');
  var HOST 	= argumen.getWithDefault('host', '127.0.0.1');
  var PORT 	= int.parse(argumen.getWithDefault('port', "2000"));
  assert(PORT is int);
  if (argumen.get("help") == "help") {
    // Colorize msg1 = new Colorize("Cara menggunakan aplikasi pack").green().bold();
    // print(new Colorize("Cara menggunakan aplikasi pack").green().bold());
    // color("Cara menggunakan tool:", front: Styles.lightGreen, isBold: false, isItalic: false, isUnderline: false);
    print("Cara menggunakan aplikasi:\n\$ dart main.dart --dir=folder/app --host=localhost --port=2000 ");
  } else {
    startWebsocket(HOST, PORT, DIR);
  }
}