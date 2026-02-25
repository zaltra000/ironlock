# دليل إعداد GitHub و GitHub Actions لتطبيق IronLock

لتتمكن من بناء التطبيق تلقائياً والحصول على ملف `APK` مباشرة من GitHub، لقد قمت مسبقاً بإعداد ملف الـ Workflow الخاص بـ GitHub Actions (موجود في المسار `.github/workflows/build-apk.yml`).

كل ما تحتاجه الآن هو اتباع هذه الخطوات لرفع المشروع وإضافة الـ Token:

## 1. رفع المشروع إلى GitHub (إنشاء Repository)
إذا لم تكن قد رفعت الكود بعد، اتبع الخطوات التالية من موجه الأوامر (Terminal) داخل مجلد المشروع:

```bash
cd ~/Documents/project/ironlocke
git init
git add .
git commit -m "الإصدار الأول من IronLock"
# اذهب لموقع github.com وقم بإنشاء مساحة عمل (Repository) جديدة فارغة باسم ironlocke مثلاً
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo-name>.git
git push -u origin main
```

## 2. كيفية إنشاء الـ Token (Personal Access Token)
للسماح لـ GitHub Actions بإنشاء Release (إصدار جديد) ورفع الـ APK فيه نيابة عنك، يُنصح بإنشاء Token وإضافته:

1. اذهب إلى حسابك في **GitHub** من المتصفح.
2. اضغط على صورتك الشخصية في أعلى اليمين واختر **Settings**.
3. انزل إلى أسفل القائمة في اليسار واضغط على **Developer settings**.
4. من القائمة اليسرى، اختر **Personal access tokens** ثم **Tokens (classic)**.
5. اضغط على زر **Generate new token** (اختر Generate new token (classic)).
6. في خانة **Note** اكتب اسماً مثل: `IronLock Android CI Builder`.
7. في خانة **Expiration** اختر `No expiration` (أو مدة تناسبك إذا أردت أماناً أعلى).
8. **أهم خطوة (الصلاحيات):** 
   - ضع علامة (صح) أمام المربع المكتوب عليه **`repo`** (تلقائياً سيحدد كل ما تحته: repo:status, repo_deployment, public_repo, repo:invite, security_events).
   - ضع علامة (صح) أمام المربع المكتوب عليه **`workflow`**.
9. انزل للأسفل واضغط على زر **Generate token**.
10. **احتفظ بالرمز (Token) الذي سيظهر لك الآن، لأنك لن تستطيع رؤيته مرة أخرى!** سيكون شكله غالباً يبدأ بـ `ghp_...`.

## 3. وضع الـ Token في إعدادات مساحة العمل (Repository Secrets)
الآن بعد أن أصبح الكود على GitHub ولديك الرمز (Token)، يجب أن تضعه في خصائص الـ Repository لكي يستخدمه الـ Workflow:

1. اذهب إلى المستودع (Repository) الخاص بمشروع IronLock على GitHub.
2. اضغط على تبويب **Settings** الموجود أسفل اسم المستودع.
3. من القائمة اليسرى، ابحث عن قسم **Security** واضغط على **Secrets and variables** ثم اختر **Actions**.
4. اضغط على الزر الأخضر **New repository secret**.
5. في خانة **Name** اكتب بالضبط: `PAT_TOKEN` (بالحروف الكبيرة لأننا استخدمنا هذا الاسم في ملف `build-apk.yml`).
6. في خانة **Secret** قم بلصق الرمز (Token) الذي حصلت عليه في الخطوة السابقة.
7. اضغط **Add secret**.

## 4. كيفية توليد الـ APK (التشغيل التلقائي من GitHub)
لقد قمت بضبط الـ Workflow ليعمل بطريقتين:
- **تلقائياً عند إضافة Tag (نسخة):** إذا قمت برفع إصدار جديد مثل `v1.0.0` سيقوم ببناء الـ APK وضعه في الإصدارات (Releases).
- **يدوياً من الموقع متى أردت (Workflow Dispatch):**
  1. اذهب إلى الـ Repository الخاصة بك في GitHub.
  2. اضغط على تبويب **Actions** في الأعلى.
  3. من القائمة اليسرى، اختر **"Build & Release IronLock APK"**.
  4. على اليمين ستجد زر **Run workflow**. اضغط عليه ثم اختر **Run workflow**.
  5. انتظر من 3 إلى 5 دقائق حتى ينتهي البناء.
  6. عند الانتهاء، ادخل على تفاصيل البناء، وفي الأسفل بقسم الـ **Artifacts** ستجد ملف `ironlock-release-apk`، اضغط عليه لتحميله مباشرة!

---
> [!TIP]
> إذا حاولت وضع `Tag` على الـ Git لإنشاء إصدار جديد، استخدم هذه الأوامر في التيرمينال:
> ```bash
> git tag v1.0.0
> git push origin v1.0.0
> ```
> هذا الأمر سيفعل كل شيء وسينشئ Release رسمياً يحمل الـ APK للتحميل المباشر للجميع في صفحة مستودعك.
