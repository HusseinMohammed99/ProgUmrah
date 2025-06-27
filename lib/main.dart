import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umrah/componets/bar.dart';

// تأكد أن المسار صحيح

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // تأكد من تهيئة Flutter Binding

  // تهيئة Supabase
  await Supabase.initialize(
    url: 'https://wydpymcqhjwezwzxrxix.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5ZHB5bWNxaGp3ZXp3enhyeGl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5NDEyMzYsImV4cCI6MjA2NjUxNzIzNn0.GBubHQxqqg1_qR6VB_NW4ae1lYG5hx1pGUCvuq-CPVs',
  );

  print("تم الاتصال بـ Supabase.");

  try {
    // محاولة تسجيل الدخول كمستخدم مصادق عليه
    final AuthResponse res = await Supabase.instance.client.auth
        .signInWithPassword(email: 'test@example.com', password: '123456789');

    final Session? session = res.session;
    final User? user = res.user;

    if (session != null && user != null) {
      print("تم تسجيل الدخول بنجاح كـ: ${user.email}");
    } else {
      print(
        "فشل تسجيل الدخول التلقائي أو المستخدم غير موجود. قد لا تتمكن من الإضافة للجدول.",
      );
      // يمكنك هنا توجيه المستخدم لصفحة تسجيل الدخول أو إظهار رسالة
    }
  } catch (e) {
    print("خطأ أثناء محاولة تسجيل الدخول: ${e.toString()}");
    print(
      "تأكد من وجود المستخدم 'test@example.com' وكلمة المرور الصحيحة في Supabase.",
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تطبيق العمرة', // عنوان وصفي للتطبيق
      home: const SideBar(), // صفحة إضافة الرحلة
    );
  }
}
