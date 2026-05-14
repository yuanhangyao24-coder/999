main.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

void main() => runApp(const KuaiShangHaoApp());

class KuaiShangHaoApp extends StatelessWidget {
  const KuaiShangHaoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "快上号",
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF1A365D),
        hintColor: const Color(0xFF90CAF9),
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

const String AES_KEY_STR = "X9s2Kp7aLz4qR6tY5bV3cN8mW2dF7gH1";
const int LEASE_SECONDS = 600;
const String GAME_ACCOUNT = "LOL_Admin001";
const String GAME_PASSWORD = "Game@Pass123456";
Map<String, Map<String, dynamic>> unlockPool = {};
String? onlineDeviceId;

String aesEncrypt(String text) {
  final key = Key(utf8.encode(AES_KEY_STR));
  final iv = IV.fromSecureRandom(16);
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: "PKCS7"));
  final encrypted = encrypter.encrypt(text, iv: iv);
  return "${iv.base64}${encrypted.base64}";
}

String aesDecrypt(String hex) {
  final key = Key(utf8.encode(AES_KEY_STR));
  final iv = IV.fromBase64(hex.substring(0, 24));
  final cipher = Encrypted.fromBase64(hex.substring(24));
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: "PKCS7"));
  return encrypter.decrypt(cipher, iv: iv);
}

class ZeusShield {
  bool checkCheat() => true;
  bool checkRemote() => true;
  bool checkDevice(String devId) {
    if (onlineDeviceId != null && onlineDeviceId != devId) return false;
    onlineDeviceId = devId;
    return true;
  }
}

class DriverLogin {
  bool loaded = false;
  String load() { loaded = true; return "驱动加载成功"; }
  String login(String accHex, String pwdHex) {
    if (!loaded) load();
    String acc = aesDecrypt(accHex);
    return "上号成功：$acc | 密码隐藏";
  }
  String clean() { loaded = false; onlineDeviceId = null; return "租期结束，清理完成"; }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController codeCtrl = TextEditingController();
  List<String> logs = [];
  int remain = 0;
  late DriverLogin driver;
  late ZeusShield shield;

  @override
  void initState() {
    super.initState();
    driver = DriverLogin();
    shield = ZeusShield();
    addLog("快上号手机上号器启动 | 宙斯盾已就绪");
  }

  void addLog(String msg) {
    setState(() => logs.add("${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} | $msg"));
  }

  String createCode() {
    String oid = DateTime.now().millisecondsSinceEpoch.toString();
    String code = md5.convert(utf8.encode(oid)).toString().substring(0,16);
    unlockPool[code] = {
      "accHex": aesEncrypt(GAME_ACCOUNT),
      "pwdHex": aesEncrypt(GAME_PASSWORD),
      "start": DateTime.now().millisecondsSinceEpoch,
      "used": false
    };
    return code;
  }

  void startLogin() {
    String code = codeCtrl.text.trim();
    if (code.isEmpty) { addLog("请输入解锁码"); return; }
    if (!unlockPool.containsKey(code)) { addLog("解锁码无效"); return; }
    var info = unlockPool[code]!;
    if (info["used"]) { addLog("已使用"); return; }
    addLog("解锁码校验通过");
    bool ok = shield.checkCheat() && shield.checkRemote() && shield.checkDevice("mobile_${Random().nextInt(9999)}");
    if (!ok) { addLog("风控拦截"); return; }
    addLog(driver.load());
    addLog(driver.login(info["accHex"], info["pwdHex"]));
    info["used"] = true;
    setState(() => remain = LEASE_SECONDS);
    startTimer();
  }

  void startTimer() async {
    while (remain > 0) {
      await Future.delayed(const Duration(seconds:1));
      setState(() => remain--);
    }
    addLog(driver.clean());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A365D),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height:20),
            Center(child: Image.network("https://p3-flow-image-sign.byteimg.com/tos-cn-i-a9rns2rl98/0020080080804088988d8d4040084001~tplv-a9rns2rl98-image.image", width: 100, height: 100)),
            const SizedBox(height:10),
            const Text("快上号 · 宙斯盾上号器", style: TextStyle(fontSize:24,color:Color(0xFF90CAF9),fontWeight:FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height:30),
            TextField(
              controller: codeCtrl,
              style: const TextStyle(color:Colors.white),
              decoration: const InputDecoration(labelText:"解锁码",labelStyle:TextStyle(color:Colors.white),filled:true,fillColor:Color(0xFF2C5282),border:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(8)))),
            ),
            const SizedBox(height:20),
            Row(
              children: [
                Expanded(child:ElevatedButton(onPressed:(){String c=createCode();setState(()=>codeCtrl.text=c);addLog("生成解锁码：$c");},style:ElevatedButton.styleFrom(backgroundColor:Color(0xFF90CAF9)),child:Text("下单获取解锁码",style:TextStyle(color:Color(0xFF1A365D))))),
                const SizedBox(width:10),
                Expanded(child:ElevatedButton(onPressed:startLogin,style:ElevatedButton.styleFrom(backgroundColor:Color(0xFF3182CE)),child:Text("一键上号"))),
              ],
            ),
            const SizedBox(height:20),
            Text("⏱ 租期剩余：${remain~/60}:${remain%60}",style:TextStyle(color:Color(0xFFFBD38D),fontSize:16,fontWeight:FontWeight.bold)),
            const SizedBox(height:15),
            const Text("📋 运行日志",style:TextStyle(color:Colors.white,fontSize:14)),
            Container(
              height:220,
              padding:EdgeInsets.all(10),
              decoration:BoxDecoration(color:Color(0xFF2C5282),borderRadius:BorderRadius.circular(8)),
              child:ListView(children:logs.map((e)=>Text(e,style:TextStyle(color:Color(0xFFE2E8F0)))).toList()),
            )
          ],
        ),
      ),
    );
  }
}
