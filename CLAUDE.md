# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GenzCinema Hotel — a cinema hotel booking system with a Spring Boot REST API backend and Flutter mobile client.

## Commands

### Backend (Spring Boot — `backend/`)

```bash
cd backend
./mvnw spring-boot:run       # Start server at http://localhost:8080/api
./mvnw clean install         # Build
./mvnw test                  # Run all tests
./mvnw package               # Build JAR to target/
```

### Mobile (Flutter — `mobile/`)

```bash
cd mobile
flutter pub get              # Install dependencies
flutter run                  # Run on emulator/device
flutter build apk            # Build Android APK
flutter analyze              # Lint
flutter test                 # Run tests
flutter pub run build_runner build   # Regenerate Riverpod code after provider changes
```

## Architecture

### Backend (Java 17 + Spring Boot 3.5.6 + SQL Server)

Layered: Controller → Service → Repository → Entity. All responses are wrapped in `ApiResponse<T>`.

- `controller/` — REST endpoints (Auth, Room, Booking)
- `service/` — Business logic (AuthService, EmailService)
- `security/` — JWT pipeline: `JwtService` generates/validates tokens, `JwtAuthFilter` attaches auth to each request, `SecurityConfig` defines public vs protected routes
- `entity/` — JPA entities mapped to SQL Server (User, Room, Booking, Hotel, Role, TypeRoom, TypeBooking, PriceConfig, PasswordResetToken)
- `dto/` — Request/response objects (LoginRequest, LoginResponse, RegisterRequest, ResetPasswordDto, ApiResponse)
- `repository/` — Spring Data JPA interfaces
- `exception/GlobalExceptionHandler.java` — Centralized error handling

JWT claims embed: `userId`, `fullName`, `role`, `roleId`. Routes under `/api/auth/**` are public; all others require a valid token.

### Mobile (Flutter + Riverpod + Dio)

- `main.dart` — Entry point; wraps app in `ProviderScope`
- `config/router.dart` — GoRouter; listens to `authProvider` and redirects on login status and role (`ADMIN` → admin dashboard, `CUSTOMER` → room list)
- `config/app_config.dart` — Central constants: base API URL, role names, storage keys
- `services/api_client.dart` — Dio singleton; interceptor auto-attaches `Authorization: Bearer {token}` from FlutterSecureStorage
- `providers/auth_provider.dart` — `StateNotifierProvider<AuthNotifier, AuthState>`; holds user, isLoading, error, isInitialized flags
- `screens/` — Organized by role: `auth/`, `customer/room/`, `admin/`, `home/`

State flow: login → `authProvider` updates → GoRouter redirects based on role.

## Key Configuration

**Backend** (`backend/src/main/resources/application.properties`):
- Server: port `8080`, context path `/api`
- Database: SQL Server at `localhost:1433`, DB name `GenzCinemaHotel`
- JWT expiry: 24 hours (`app.jwt.expiration=86400000`)
- Password reset token expiry: 15 minutes

**Mobile** — API base URL and role constants are in `mobile/lib/config/app_config.dart`. Update the base URL here when switching environments (local vs device vs emulator — emulator uses `10.0.2.2` to reach host localhost).

## API Surface

```
POST  /api/auth/login              # public
POST  /api/auth/register           # public
POST  /api/auth/request-reset      # public
GET   /api/auth/verify-token       # public
POST  /api/auth/reset-password     # public

GET   /api/rooms                   # authenticated
GET   /api/rooms/available
GET   /api/rooms/hotel/{hotelId}
GET   /api/rooms/{id}
POST  /api/rooms                   # ADMIN only
PUT   /api/rooms/{id}              # ADMIN only
DELETE /api/rooms/{id}             # ADMIN only

GET   /api/bookings                # ADMIN only
GET   /api/bookings/user/{userId}
GET   /api/bookings/{id}
POST  /api/bookings
PUT   /api/bookings/{id}/status    # ADMIN only
```

## Development Notes

- Error messages and email templates are in Vietnamese (UTF-8)
- `spring.jpa.hibernate.ddl-auto=update` — schema auto-updates on startup; no manual migrations needed in dev
- After modifying any Riverpod `@riverpod`-annotated provider, run `build_runner build` to regenerate `.g.dart` files
