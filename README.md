# Pesa: native Android app (Flutter), stage 1

A real Android app written in Flutter and Dart (not a web page inside an app).

## Build the APK online (no Android Studio)
1. Create a private repository on github.com and upload everything in this folder
   (the hidden `.github` folder may need creating by hand: Add file > Create new file >
   `.github/workflows/build-apk.yml`, then paste the contents of `github-workflow.yml`).
2. Actions tab > **Build Flutter APK** > Run workflow. The first build takes 10 to 15 minutes.
3. Download **pesa-flutter-apk** from the finished run, unzip it, and install `app-release.apk`.
   If the run turns red, open the failed step and send me its last lines.

The app installs as a separate app (`com.pesa.pesa_app`), so it can sit next to the old one.

## Move your data from the web/Capacitor app
Old app: Settings > Backup and currency > "Show backup as text instead" > copy the text.
New app: Settings > Restore from backup > Paste > Restore.
Everything is kept, including budgets, goals, debts, planned payments and shopping lists
(they are stored inside the file and will show up when those screens are added).

## What stage 1 contains
Home with Day/Week/Month/Year/All, summary, accounts and records; add, edit and delete
transactions (expense, income, transfer; categories and subcategories); accounts; records by month;
light/dark/system theme; animated name intro; floating navigation; backup copy and restore;
currency label; erase.

## Next stages
2. Budgets, goals, debts, planned payments, shopping lists, reminders with real phone notifications.
3. Reports and charts.
4. PIN and fingerprint lock, attachments, Excel/CSV export, sharing files.
5. Online sync with your PHP server, Sign in with Google, Google Drive backup with real background auto backup.

## Tests
The data and calculation code is plain Dart and is tested against numbers produced by the web app:
`dart test/logic_test.dart`
