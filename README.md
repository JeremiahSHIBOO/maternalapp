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

The mother experience uses three tabs: **Today**, **Baby**, and **Care**. Today contains check-ins, wellbeing, recent symptoms, and the next appointment. Baby contains an interactive procedural 3D illustration with rotation, zoom, optional gentle motion, a still view, and a week selector. Care groups appointments and partner sharing/messages. The partner experience uses **Today**, **Baby**, and **Together**, and only displays categories the mother has shared.

Connected flows include account sign-in/sign-up, role selection, pregnancy dating, daily check-ins with optional manually entered readings, symptom logs, mother-controlled partner connections, selective sharing, and private messages. Run `maternal-health-app/supabase/dashboard_appointments.sql` after the main schema to enable appointment creation, editing, and cancellation. Existing Supabase projects must apply the current main schema to enable partner functions and permissions. No database changes are applied automatically by the app.

The baby viewer generates shaded 3D geometry locally, without remote assets or a new rendering dependency. Its early-development and curled-baby forms are stylized concepts with broad stage changes, not reviewed weekly anatomical models or scans. Motion starts paused and respects reduced-motion preferences. Professionally reviewed developmental meshes are still needed for anatomical fidelity. Clinician assignments, expenses, baby-care logs, and push notifications remain unfinished.

Run `flutter analyze --no-fatal-infos` and `flutter test` from the mobile directory for static checks and UI regression tests. The repository has pre-existing informational lint findings.

## Project layout

- `maternal-health-app/apps/mobile`: Flutter client
- `maternal-health-app/supabase/schema.sql`: Supabase tables, auth trigger, and row-level security policies
- `maternal-health-app/backend`: separate FastAPI prototype, currently not wired to the Flutter app

