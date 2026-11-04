# بناء ALBYATE v0.3.2 للأندرويد

## المتطلبات
Flutter SDK متوافق مع Dart >=3.6، Android SDK، Java 17، واتصال إنترنت لتحميل الحزم.

## أوامر البناء
```bash
flutter doctor
flutter pub get
flutter analyze
flutter build apk --debug
```
ملف الاختبار: `build/app/outputs/flutter-apk/app-debug.apk`.

لإنشاء إصدار قابل للتوزيع، اضبط مفتاح توقيع release خاص بك (إعداد هذه النسخة يوقّع release بمفتاح debug **للتجربة فقط**)، ثم شغّل `flutter build apk --release`.

إذا احتجت توليد ملفات Gradle wrapper المفقودة، شغّل `flutter create . --platforms=android --project-name albyate_for_solar_inverter --org com.albyate` بعد أخذ نسخة احتياطية، وراجع معرّف الحزمة قبل البناء. ملفات Android المرفقة تتضمن إعدادات Gradle لكن لا تتضمن `gradle-wrapper.jar` ولا `gradlew`، لأن أدوات Flutter/Gradle غير متاحة في بيئة التجهيز.

## توافق البيانات
اسم الحزمة `com.albyate.solarinverter` واسم قاعدة البيانات `albyate_center.db` وإصدار المخطط 2 لم تتغير. الحسابات القديمة ذات SHA-256 تُقبل وتُرقّى عند أول دخول ناجح. لا تحذف التطبيق القديم قبل أخذ نسخة احتياطية؛ إعادة تثبيت التطبيق بعد حذفه قد تحذف بياناته المحلية.

## قيود معروفة
لم يُجرَ `flutter analyze` أو بناء APK أو اختبار تشغيل فعلي. يلزم اختبار Firebase/App Check، OCR، قراءة الباركود، الفواتير، صلاحيات الموظفين، النسخ الاحتياطي، واسترجاع البيانات قبل التشغيل الإنتاجي. لا تستخدم توقيع debug للتوزيع النهائي.
