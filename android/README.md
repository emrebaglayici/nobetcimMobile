# Nöbetçim Cebinde Android

Kotlin + Jetpack Compose Android uygulaması. Backend bağlantısı, iOS tarafıyla aynı yeni API sözleşmesini kullanır:

```text
https://nobetcimbackend.vercel.app/api/v1
X-API-Key: nbcm_...
```

API anahtarını yerel `~/.gradle/gradle.properties` veya proje dışı bir ortam değişkeniyle verin:

```properties
NOBETCIM_API_KEY=nbcm_your_api_key_here
```

Android Studio ile `android/` klasörünü açıp `app` modülünü çalıştırın.
