import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision/main.dart';
import 'package:vision/profileInfo.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert' show json;
import 'package:path/path.dart';
import 'package:async/async.dart';


class ProfileSheet extends StatefulWidget {
  ProfileInfo profileInfo;
  BuildContext buildContext;
  Function changePic;
  ProfileSheet({this.profileInfo,this.buildContext,this.changePic});

  @override
  State<StatefulWidget> createState() {
    return ProfileSheetState();
  }
}

class ProfileSheetState extends State<ProfileSheet> {
  bool editMode = false;
  Future<File> imageFile;
  File image;
  String mobileNumber,name;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    mobileNumber = widget.profileInfo.phNo;
    name = widget.profileInfo.name;
  }

  @override
  Widget build(BuildContext context) {
    return editMode ? _editProfile() : _profile();
  }

  pickImageFromGallery(ImageSource source) {
    setState(() {
      imageFile = ImagePicker.pickImage(source: source);

    });
    if (imageFile != null) {
      imageDialog();
    }
  }

  Widget showImage() {
    return FutureBuilder<File>(
      future: imageFile,
      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return Image.file(
            snapshot.data,
          );
        } else if (snapshot.error != null) {
          return const Text(
            'Error Picking Image',
            textAlign: TextAlign.center,
          );
        } else {
          return const Text(
            'No Image Selected',
            textAlign: TextAlign.center,
          );
        }
      },
    );
  }

  void uploadImage(File imageFile) async {
    print(imageFile.path);
    var stream = new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();

    var uri = Uri.parse(MyApp.getURL()+"/api/edit_profile_picture/?username="+widget.profileInfo.username);

    var request = new http.MultipartRequest("POST", uri);
    var multipartFile = new http.MultipartFile('file', stream, length,
        filename: basename(imageFile.path));
    //contentType: new MediaType('image', 'png'));

    request.files.add(multipartFile);
    var response = await request.send();
    var responseObj = await Response.fromStream(response);
    Map<String, dynamic> responseBody = json.decode(responseObj.body);
    setState(() {
      widget.profileInfo.imageUrl = responseBody['image_url'];
    });
    widget.changePic(responseBody['image_url']);
    saveProfile();
    print("Profile_pic: "+responseObj.body);
  }

  void imageDialog() {
    Dialog imageDialog = Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0)), //this right here
      child: Wrap(
        children:<Widget>[
        Container(
        width: 300.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(padding: EdgeInsets.all(15.0), child: showImage()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:<Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(widget.buildContext).pop();
                },
                child: Text(
                  'CANCEL',
                ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 8),
                ),
                RaisedButton(
                onPressed: () {
                    imageFile.then((imageLoaded){
                      image = imageLoaded;
                      uploadImage(image);
                    });
                  Navigator.of(widget.buildContext).pop();
                },
                child: Text(
                  'SAVE',
                ),
                ),
              ]),
          ],
        ),
      ),]),
    );
    showDialog(
        context: widget.buildContext, builder: (BuildContext context) => imageDialog);
  }

  Widget _editProfile() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 100.0,
                  height: 100.0,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    image: DecorationImage(
                      image: new NetworkImage(
                          MyApp.getURL() +
                              widget.profileInfo.imageUrl),
                      fit: BoxFit.cover,
                    ),
                    borderRadius:
                        new BorderRadius.all(new Radius.circular(50.0)),
                    border: new Border.all(
                      color: Colors.greenAccent,
                      width: 1.0,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  width: 100.0,
                  height: 100.0,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius:
                        new BorderRadius.all(new Radius.circular(50.0)),
                  ),
                ),
                GestureDetector(
                  child: Container(
                    alignment: Alignment.center,
                    child: Icon(Icons.add_a_photo),
                  ),
                  onTap: () {
                    pickImageFromGallery(ImageSource.gallery);
                  },
                )
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 16),
            child: TextFormField(
              onChanged: (String text){
                name = text;
              },
              initialValue: widget.profileInfo.name,
              decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  )),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 16),
            child: TextFormField(
              onChanged: (String text){
                mobileNumber = text;
              },
              initialValue: mobileNumber,
              decoration: InputDecoration(
                  labelText: "Moble Number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  )),
            ),
          ),
          Container(
              margin: EdgeInsets.fromLTRB(0, 0, 8, 8),
              child: Row(
                children: <Widget>[
                  Spacer(),
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    child: FlatButton(
                      shape: Border.all(
                          color: Colors.green,
                          width: 1,
                          style: BorderStyle.solid),
                      child: Text('CANCEL'),
                      onPressed: () {
                        setState(() {
                          editMode = false;
                        });
                      },
                    ),
                  ),
                  RaisedButton(
                    child: Text('DONE'),
                    onPressed: () {
                      update();
                    },
                  ),
                ],
              )),
          Spacer(),
        ],
      ),
    );
  }

  saveProfile() async{
    String profile = json.encode(ProfileInfo.toJson(widget.profileInfo));

    final prefs = await SharedPreferences.getInstance();

    prefs.setString('profile_info', profile);
  }

  void update() async{
    var response;
    String firstName = "",lastName = "";
    List<String> names = name.split(" ");
    firstName = names[0];
    if(names.length>1){
      lastName = names.sublist(1).join(" ");
    }
    try{
      response = await http.post(
          MyApp.getURL() +'/api/edit_profile/',
          body: {'username': widget.profileInfo.username, 'phone':mobileNumber, 'first_name':firstName,'last_name':lastName});
    }catch(e){
      Fluttertoast.showToast(
        msg: 'Something went wrong!',
        toastLength: Toast.LENGTH_SHORT,
      );
      print(e.toString());
    }
    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = json.decode(response.body);
      print(responseBody.toString());
      print("Status: "+responseBody['status'].toString());
      if(responseBody['status']== 200){
        Fluttertoast.showToast(
          msg: 'Profile Successfully Updated',
          toastLength: Toast.LENGTH_SHORT,
        );
        setState(() {
          widget.profileInfo.name = name;
          widget.profileInfo.phNo = mobileNumber;
          editMode = false;
        });
        saveProfile();
      }else{
        Fluttertoast.showToast(
          msg: 'Something Went Wrong!',
          toastLength: Toast.LENGTH_SHORT,
        );
      }
      // If server returns an OK response, parse the JSON.

    } else {
      Fluttertoast.showToast(
        msg: 'Please check your internet connection',
        toastLength: Toast.LENGTH_SHORT,
      );
      // If that response was not OK, throw an error.
      print("error");
      // throw Exception('Failed to load post');
    }
  }

  Widget _profile() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          Container(
            width: 50.0,
            height: 50.0,
            decoration: BoxDecoration(
              color: Colors.green,
              image: DecorationImage(
                image: new NetworkImage(MyApp.getURL() +
                    widget.profileInfo.imageUrl),
                fit: BoxFit.cover,
              ),
              borderRadius: new BorderRadius.all(new Radius.circular(50.0)),
              border: new Border.all(
                color: Colors.greenAccent,
                width: 1.0,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SingleChildScrollView(
                      child: Container(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Row(children: <Widget>[
                          Text(
                            widget.profileInfo.name,
                          ),
                          Text(
                            '.' + widget.profileInfo.username,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ]),
                      ),
                    ),
                    SingleChildScrollView(
                      child: Text(
                        widget.profileInfo.email,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              _clearData();
              logout();
            },
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              setState(() {
                editMode = true;
              });
            },
          )
        ],
      ),
    );
  }

  void _clearData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  void logout() {
    Navigator.pop(widget.buildContext);
    Navigator.pushReplacementNamed(widget.buildContext, '/login');
  }
}
