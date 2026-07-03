# Flow Example App

A polished demo of the Flow router showcasing typed navigation, guards, middleware, and web-ready URLs.

## Run

```bash
cd example
flutter run          # Mobile / desktop
flutter run -d chrome # Web
```

## Features Demonstrated

| Screen | Feature |
|--------|---------|
| **Home** | Typed routes, live URL display, push overlay |
| **Explore** | User list with `UserRoute(id: n).location` |
| **User Detail** | Path params, query tabs, `context.replace` |
| **Profile** | Auth state, sign in/out |
| **Settings** | `SettingsGuard` protection |
| **Login** | `AuthGuard` redirect with return URL |
| **About** | Imperative `push` overlay |

## Try These URLs (Web)

```
http://localhost:port/home
http://localhost:port/explore
http://localhost:port/profile
http://localhost:port/users/42
http://localhost:port/users/42?tab=activity
http://localhost:port/settings
http://localhost:port/login
```

## Project Structure

```
example/lib/
├── main.dart           # App entry
├── router.dart         # FlowRouter configuration
├── routes/             # Typed route classes
├── pages/              # Screen widgets
├── auth/               # Auth guard & state
├── theme/              # Material 3 dark theme
└── widgets/            # Shared UI components
```
