# MyOrders Dahab

Delivery platform for Dahab, South Sinai: food, drinks, supermarket, pharmacy and
"send anything" courier orders, with apps for customers, riders, stores and the admin.

| Part | Folder | Platforms | Who uses it |
| --- | --- | --- | --- |
| Customer app | `apps/customer` | Android, iOS, web | People ordering in Dahab |
| Rider app | `apps/rider` | Android, iOS, web | Delivery riders |
| Dashboard | `apps/dashboard` | Web | Stores (partner portal) and the MyOrders admin |
| Shared code | `packages/core` | | Models, backend access, theme, Arabic/English text, maps |
| Backend | `supabase` | Supabase (Postgres) | Database, security rules, order logic |

Everything is in Arabic and English, using the light beach/teal design and the Cairo font.

## Run it

Install [Flutter](https://docs.flutter.dev/get-started/install) (3.35 or newer), then:

```sh
cd apps/customer      # or apps/rider, apps/dashboard
flutter pub get
flutter run -d chrome # or an Android/iOS device
```

Without backend keys every app runs in **demo mode** on sample data:

- Customer: sign in with any phone number and code `123456`. New orders move through
  their statuses on their own so you can see live tracking.
- Rider: `rider@myorders.app`, any password.
- Dashboard: `partner@myorders.app` (Blue Hole Restaurant) or `admin@myorders.app`, any password.

To use the real backend, pass the keys at build time (see [docs/integrations.md](docs/integrations.md)):

```sh
flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
            --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

## How an order moves

```
customer places order ─► pending ─► store accepts ─► preparing ─► ready
                                                                   │
            delivered ◄── rider picks up (picked_up) ◄── rider takes the order
```

Courier orders ("Delivery" tile) skip the store: pending → a rider takes it (accepted) →
picked up → delivered. Prices are always recalculated on the server (`place_order`), and
each role can only make its own status changes (`update_order_status`).

The platform keeps a 15% commission on each store order's subtotal
(`platformCommission` in `packages/core/lib/src/data/repository.dart` and in
`place_order`). Delivery fees are set per store; courier orders cost 40 EGP.

## Tests

```sh
(cd packages/core && flutter test)
(cd apps/customer && flutter test)
(cd apps/rider && flutter test)
(cd apps/dashboard && flutter test)
```

The SQL in `supabase/migrations` was checked against Postgres 16 with a full order
cycle (customer → partner → rider → admin) and the security rules.

## Demo catalog

The sample stores and products live in `packages/core/lib/src/data/mock_data.dart`.
After changing them, regenerate the database seed with `python3 supabase/gen_seed.py`.
