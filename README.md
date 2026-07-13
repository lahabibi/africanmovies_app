# AfricanMovies

Flutter mobile app for AfricanMovies.

## API configuration

The app defaults to the production API:

```text
https://api.africanmovies.com/api
```

For local backend testing in debug or profile builds, pass the API origin at
run time:

```bash
flutter run \
  --dart-define=AFRICAN_MOVIES_API_BASE_URL=http://YOUR_DEVICE_REACHABLE_HOST:3200/api
```

Release builds always use the production API and must not be shipped with a
local, LAN, staging, or temporary tunnel API URL.
