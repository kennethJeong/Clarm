import 'dart:io';
import 'package:Clarm/models/providers.dart';
import 'package:Clarm/theme.dart';
import 'package:Clarm/utils/color_print.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mailer/smtp_server/gmail.dart';

class ContactUs extends ConsumerStatefulWidget {
  const ContactUs({
    super.key,
  });

  @override
  ContactUsState createState() => ContactUsState();
}

class ContactUsState extends ConsumerState<ContactUs> {
  final _formKey = GlobalKey<FormState>();

  String contactName = '';
  String contactEmail = '';
  String contactContent = '';

  Future<void> sendEmail(String contactName, String contactEmail, String contactContent) async {
    var body = 'DateTime: ${DateTime.now()}';
    body += '\n Name: $contactName';
    body += '\n Email: $contactEmail';
    body += '\n Content: $contactContent';

    String username = 'dev.kennyJ@gmail.com';
    String password = Platform.isAndroid ? dotenv.env['gmail_pw_aos'].toString() : dotenv.env['gmail_pw_ios'].toString();
    String bccUsername = 'eunuism@gmail.com';

    var smtpServer = gmail(username, password);
    final equivalentMessage = Message()
      ..from = Address(username, 'Clarm')
      ..subject = '[Inquiry [Clarm]] :: ${DateTime.now()}'
      ..recipients.add(Address(username))
      ..bccRecipients.add(Address(bccUsername))
      ..text = body;

    try {
      await send(equivalentMessage, smtpServer);
      printRed("A mail is sent");
    } catch (error) {
      printRed(error.toString());
    }
  }

  @override
  void initState() {
    super.initState();

  }

  Future alertDialogAfterEmail(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          title: null,
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.2,
            // padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Your feedback has been sent.",
                    style: TextStyle(
                      color: ref.watch(isDarkMode) ? Colors.white : MyTheme.primaryColor,
                      fontSize: 17,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  Text(
                    "Thanks you :)",
                    style: TextStyle(
                      color: ref.watch(isDarkMode) ? Colors.white : MyTheme.primaryColor,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 40,
                  width: MediaQuery.of(context).size.width * 0.4,
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(MyTheme.primaryColor),
                    ),
                    onPressed: () => Navigator.popAndPushNamed(context, '/clarm'),
                    child: const Center(
                      child: Text(
                        "Close",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Grey Top Bar for Dragging top to bottom
            SizedBox(
              width: double.maxFinite,
              height: 20,
              child: Center(
                child: Container(
                  width: 100,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(20)
                    ),
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),

            Expanded(
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.only(bottom: 25),
                child: Container(
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: MyTheme.primaryColor,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            "CONTACT US",
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontSize: 20,
                              color: MyTheme.primaryColor,
                              fontWeight: FontWeight.w700
                            )
                          ),
                        ),
                      ),
                      Container(
                        height: 1,
                        width: MediaQuery.of(context).size.width * 0.4,
                        color: Colors.black12,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 25, bottom: 0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: TextFormField(
                                      validator: (inputName) {
                                        if (inputName == null || inputName.isEmpty) {
                                          return 'Please enter your name';
                                        } else {
                                          contactName = inputName;
                                          return null;
                                        }
                                      },
                                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                        fontSize: 14,
                                        color: ref.watch(isDarkMode) ? Colors.white : Colors.black
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.only(left: 5, bottom: 5),
                                        hintText: 'Name',
                                        hintStyle: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: TextFormField(
                                      validator: (inputEmail) {
                                        if (inputEmail == null || inputEmail.isEmpty) {
                                          return 'Please enter your E-mail';
                                        } else {
                                          contactEmail = inputEmail;
                                          return null;
                                        }
                                      },
                                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                        fontSize: 14,
                                        color: ref.watch(isDarkMode) ? Colors.white : Colors.black
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.only(left: 5, bottom: 5),
                                        hintText: 'Email',
                                        hintStyle: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey
                                        )
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: MyTheme.primaryColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: TextFormField(
                                        validator: (inputContent) {
                                          if (inputContent == null || inputContent.isEmpty) {
                                            return 'Please enter your query';
                                          } else {
                                            contactContent = inputContent;
                                            return null;
                                          }
                                        },
                                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                          fontSize: 14,
                                          color: ref.watch(isDarkMode) ? Colors.white : Colors.black
                                        ),
                                        keyboardType: TextInputType.multiline,
                                        maxLines: null,
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.all(10),
                                          border: InputBorder.none,
                                          hintText: 'Please write down your feedback to Clarm ;)',
                                          hintStyle: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 70,
                        child: Center(
                          child: SizedBox(
                            height: 40,
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(MyTheme.primaryColor),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  sendEmail(contactName, contactEmail, contactContent);
                                  alertDialogAfterEmail(context);
                                }
                              },
                              child: const Center(
                                child: Text(
                                  "Send",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}