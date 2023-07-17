import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_flutter/constants.dart';
import 'package:tiktok_flutter/models/user.dart' as model;
import 'package:tiktok_flutter/views/screens/auth/login_screen.dart';
import 'package:tiktok_flutter/views/screens/home_screen.dart';

class AuthController extends GetxController {
  static AuthController instance=Get.find();
  late Rx<User?> _user;
late  Rx<File?> _pickedImage;

File? get profilePhoto=> _pickedImage.value;
User get user => _user.value!;

@override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    _user=Rx<User?>(firebaseAuth.currentUser);
    _user.bindStream(firebaseAuth.authStateChanges());
    ever(_user, _setInitialScreen);

  }

  _setInitialScreen(User? user){
  if(user== null){
    Get.offAll(()=>LoginScreen());
  }else{
    Get.offAll(()=> HomeScreen());
  }
  }

  void pickImage() async {
    final pickedImage= await ImagePicker().pickImage(source: ImageSource.gallery);
    if(pickedImage!=null){
      Get.snackbar("Profile picture", "You have secessfully slected your profile picture");

    }
    _pickedImage=Rx<File?>(File(pickedImage!.path));


  }


  //upload to storage
  Future<String> _uploadToStorage(File image) async {
    Reference ref = firebaseStorage
        .ref()
        .child('profilePics')
        .child(firebaseAuth.currentUser!.uid);

UploadTask uploadTask =  ref.putFile(image);
TaskSnapshot snap=await uploadTask;
String downloadUrl= await snap.ref.getDownloadURL();
return downloadUrl;
  }

  //register user
  void registerUser(
      String username, String email, String password, File? image) async {
    try {
      if (username.isNotEmpty &&
          email.isNotEmpty &&
          password.isNotEmpty &&
          image != null) {
        // save a user
        UserCredential cred = await firebaseAuth.createUserWithEmailAndPassword(
            email: email, password: password);
        String downloadUrl= await _uploadToStorage(image);
        model.User user=model.User(name: username,
            profilePhoto: downloadUrl, email: email, uid: cred.user!.uid);
      await firestore.collection('users').doc(cred.user!.uid).set(user.toJson());

      }else{
        Get.snackbar('Error creating Account', "Please enter all the field");
      }
    } catch (e) {
      Get.snackbar('Error creating a account', e.toString());
    }
  }
  void loginUser(String email,String password) async{
try{
if(email.isNotEmpty &&
    password.isNotEmpty){
await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
print('log sucess');
}else{
  Get.snackbar('Error Logging in', "Please enter all the field");
}
}catch(e){
  Get.snackbar('Error logging in', e.toString());
}
  }

  signOut()async{
  await firebaseAuth.signOut();
  }

}
