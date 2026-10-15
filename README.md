# MatruCare maternal health companion

This repository contains a Flutter mobile app in `maternal-health-app/apps/mobile` and an unfinished FastAPI prototype in `maternal-health-app/backend`. The mobile app uses Supabase directly for authentication and data. The FastAPI service is not part of the mobile runtime.

## Run the mobile app

1. Create a Supabase project.
2. Run [`maternal-health-app/supabase/schema.sql`](maternal-health-app/supabase/schema.sql) in the Supabase SQL editor.
3. In `maternal-health-app/apps/mobile/.env`, replace the two placeholder values with your project's URL and public anon/publishable key. Never use the service-role key in a mobile app.
4. From `maternal-health-app/apps/mobile`, run:

   ```powershell
   flutter run -d <device_name>
   ```

`flutter run` resolves dependencies automatically. Email/password registration may require email confirmation, depending on Supabase Auth settings. Google sign-in also requires OAuth credentials and the `com.matrucare.app://login-callback` redirect URL in Supabase.

The current connected flows are account sign-in/sign-up, role selection, pregnancy dating from the last menstrual period, daily check-ins, and symptom logs. Supabase row-level security restricts those records to the signed-in user. Partner sharing, clinician assignments, appointments, expenses, baby-care logs, and push notifications are not implemented yet; those screens should not be treated as live clinical workflows.

## Project layout

- `maternal-health-app/apps/mobile`: Flutter client
- `maternal-health-app/supabase/schema.sql`: Supabase tables, auth trigger, and row-level security policies
- `maternal-health-app/backend`: separate FastAPI prototype, currently not wired to the Flutter app

