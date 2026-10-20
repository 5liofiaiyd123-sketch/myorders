# Going live: accounts and keys

The code is complete. These are the outside services it needs before real customers
can use it, in the order to set them up.

## 1. Supabase (database, sign-in, live updates) — required

1. Create a project at [supabase.com](https://supabase.com). Pick the Frankfurt
   (`eu-central-1`) region, the closest to Egypt.
2. Create the database. The simplest way: open **SQL Editor** in the Supabase
   dashboard, paste the whole of `supabase/migrations/20261020000000_init.sql` and
   run it. To start with the demo stores and menus, run `supabase/seed.sql` the
   same way. (With the [Supabase CLI](https://supabase.com/docs/guides/cli):
   `supabase init`, `supabase link --project-ref <ref>`, then `supabase db push`.)
3. In **Project settings → API keys** copy the project URL and the publishable key.
   Build every app with them:
   ```sh
   --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
   ```
4. **Staff accounts.** In **Authentication → Users** create an email user for each
   admin, store and rider, then set their role in the SQL editor:
   ```sql
   update profiles set role = 'admin' where email = 'you@example.com';
   update profiles set role = 'partner', store_id = 'blue-hole' where email = 'store@example.com';
   update profiles set role = 'rider', full_name = 'Ahmed', phone = '+2010...' where email = 'rider@example.com';
   ```

## 2. SMS for customer sign-in — required

Customers sign in with their phone number and a 6-digit code. In Supabase
**Authentication → Sign In / Providers → Phone**, enable phone sign-in and connect an
SMS provider. Twilio and Vonage both deliver to Egyptian numbers; expect roughly
$0.05–0.10 per message. Until this is set, phone sign-in fails on the live backend.

## 3. Maps — required before launch

The apps use OpenStreetMap through `flutter_map`. The public OSM tile server is fine
for testing but its usage policy forbids production apps. Create a free key at
[MapTiler](https://www.maptiler.com) (100k tile loads per month free) and build with:

```sh
--dart-define=MAP_TILES_URL=https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=YOUR_KEY
```

"Directions" in the rider app opens Google Maps, which needs no key.

## 4. Support WhatsApp number

Customers tap **Help & support** to open WhatsApp. Set your business number
(international format, digits only):

```sh
--dart-define=SUPPORT_WHATSAPP=2010XXXXXXXX
```

## 5. Card payments — optional, after launch

Checkout offers cash on delivery; the card option is shown as "coming soon".
To accept cards, open a merchant account with [Paymob](https://paymob.com) (cards,
Meeza, wallets such as Vodafone Cash), then add a Supabase Edge Function that creates
the payment and a webhook that marks the order as paid. The `payment` column on
`orders` already accepts `card`.

## 6. Push notifications — optional

Order screens update live while the app is open (Supabase Realtime). To notify
people when the app is closed, add Firebase Cloud Messaging and send a push from a
database webhook on `orders` status changes.

## 7. Publishing the apps

- **Google Play**: one-time $25 developer account. `flutter build appbundle` in
  `apps/customer` and `apps/rider`.
- **Apple App Store**: $99 per year, and a Mac to build. `flutter build ipa`.
- **Dashboard**: `flutter build web` in `apps/dashboard` and host the `build/web`
  folder on any static host (Netlify, Vercel, Cloudflare Pages, Firebase Hosting).

Change the app ids (`com.myorders.dahab.*`) before the first upload if you want a
different one; they can't be changed after publishing.
