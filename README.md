# Smart IoT Gateway Controller

A prototype iOS companion app for monitoring and configuring simulated smart environmental devices, including HVAC units, temperature and humidity sensors, and a gateway hub. It displays device status and telemetry, supports HVAC power and temperature controls and sampling-rate updates, and provides bridge diagnostics.

Built for the Smart IoT Gateway Controller assessment, the app uses Clean Architecture with Presentation, Domain and Data layers. A UIKit navigation flow hosts a SwiftUI device detail screen and an embedded Flutter diagnostics view. The native data layer exchanges requests and responses with a local Flutter simulator over a platform channel, device data and state changes are simulated in memory, with no live backend or physical devices.

## Contents

1. [Requirements](#1-requirements)
2. [Build and run](#2-build-and-run) (Flutter integration guide)
3. [Architecture overview](#3-architecture-overview)
4. [Data flow](#4-data-flow)
5. [Bridge documentation](#5-bridge-documentation)
6. [Testing](#6-testing)

---

## 1. Requirements

| Tool | Version used |
|---|---|
| Xcode | 27.2 (build 27B52) |
| Flutter | 3.47.9 (stable) |
| Dart | 3.13.7 |
| Swift | Apple Swift 6.4.2 (the packages require Swift tools 6.4) |
| iOS deployment target | 17.0 (app target) |

Tested on the iOS Simulator. A physical device needs a signing team set on the app target, which this repository does not include.

---

## 2. Build and run

### Flutter integration approach

The Flutter module (`flutter_iot_module/`) is embedded as a **local module** using Flutter's Swift Package Manager add-to-app integration. `flutter build swift-package` generates a local Swift package (`FlutterNativeIntegration`) that the Xcode project references in place. No CocoaPods and no prebuilt XCFrameworks are committed.

The generated output lives in `flutter_iot_module/build/`, which is **git-ignored**, so it must be generated once after cloning.

### Steps

```bash
# 1. Fetch Dart dependencies
cd flutter_iot_module
flutter pub get

# 2. Generate the Swift package for iOS
flutter build swift-package --platform ios --no-codesign
cd ..
```

Check that `flutter_iot_module/build/ios/SwiftPackages/` now contains `FlutterNativeIntegration/` and `Scripts/`.

```bash
# 3. Open the iOS project
open IoTGatewayApp/IoTGatewayApp.xcodeproj
```

4. In Xcode, wait for package resolution to finish (the local packages `Domain`, `DataLayer` and the generated Flutter packages are resolved from relative paths).
5. Select the **IoTGatewayApp** scheme and an iPhone simulator, then press **Run** (Cmd+R).

### How the Xcode project is wired to Flutter

These settings are already stored in the project, they are listed so the setup can be reviewed or reproduced:

- Package dependency: the generated `FlutterNativeIntegration` package, referenced in place (relative to the project) and linked to the app target.
- Build settings on the app target:
  - `FLUTTER_SWIFT_PACKAGE_OUTPUT = $SRCROOT/../flutter_iot_module/build/ios/SwiftPackages`
  - `FLUTTER_APPLICATION_PATH = $SRCROOT/../flutter_iot_module`
  - `ENABLE_USER_SCRIPT_SANDBOXING = NO`
- Scheme pre-action: `/bin/sh $FLUTTER_SWIFT_PACKAGE_OUTPUT/Scripts/flutter_integration.sh prebuild`
- Build phase run script: `/bin/sh $FLUTTER_SWIFT_PACKAGE_OUTPUT/Scripts/flutter_integration.sh assemble` (dependency analysis off, input file list `FlutterAssembleInputs.xcfilelist`)

After changing Dart code, building from Xcode re-assembles the Flutter app automatically because `FLUTTER_APPLICATION_PATH` is set. If a Dart dependency is added, re-run step 2.

### Troubleshooting

| Symptom | Fix |
|---|---|
| Xcode cannot find the `FlutterNativeIntegration` package | Run step 2 and check the folder exists, then File > Packages > Reset Package Caches |
| Spinner forever or "Can't reach the device service" | The Flutter package is stale or missing, re-run step 2 |

---

## 3. Architecture overview

```
┌─────────────────────────── Presentation ───────────────────────────┐
│  UIKit: Coordinator, Device list      SwiftUI: Device detail       │
│  Diagnostics: UIKit container + embedded Flutter view               │
│  ViewModels (@Observable, @MainActor)  ──►  Use cases only          │
└─────────────────────────────────┬───────────────────────────────────┘
┌──────────────────────── Domain (pure Swift) ───────────▼────────────┐
│  Entities · Use cases (business rules) · Repository protocols ·     │
│  DomainError                       (imports Foundation only)        │
└─────────────────────────────────▲───────────────────────────────────┘
┌──────────────────────────── Data ──────────────────────┴────────────┐
│  Repository implementations · DTOs · Mappers · BridgeClient ·       │
│  ErrorMapper · IoTTransport protocol                                │
└─────────────────────────────────┬───────────────────────────────────┘
                 FlutterChannelTransport (the only Flutter channel code)
                                  │  FlutterMethodChannel, JSON envelope
┌─────────────────────────────────▼───────────────────────────────────┐
│  Flutter: BridgeHandler → BridgeDispatcher → DeviceSimulator        │
│  + Dart diagnostics screen                                          │
└─────────────────────────────────────────────────────────────────────┘
```

### Repository layout

```
IoTGateway/
├── flutter_iot_module/lib/
│   ├── bridge/                  Request handling, dispatch, errors and log
│   ├── diagnostics/             Diagnostics screen and log card
│   └── simulator/               Simulated devices and seed data
├── IoTGatewayApp/IoTGatewayApp/ iOS app target
│   ├── App/                     AppDelegate, SceneDelegate, AppDependencies
│   ├── Coordinators/            AppCoordinator (navigation), ScreenFactory (screen assembly)
│   ├── Presentation/            Device list (UIKit), Device detail (SwiftUI), Diagnostics
│   └── FlutterChannelTransport.swift
└── Packages/
    ├── Domain/Sources/Domain/   Entities, Errors, Repositories, UseCases
    └── DataLayer/Sources/DataLayer/  Bridge, DTOs, Mappers, Repositories
```

### Layer rules

1. Dependencies point inward: Presentation depends on Domain, Data depends on Domain, Domain depends on nothing but Foundation.
2. `Domain` and `DataLayer` are separate Swift packages, so the compiler enforces that Domain cannot import UIKit, SwiftUI or Flutter, and that `DataLayer` cannot import Flutter.
3. Flutter's channel API (`FlutterMethodChannel`) is used in exactly one class, `FlutterChannelTransport`. The engine is created in `AppDependencies`, and `ScreenFactory` creates the `FlutterViewController` for the diagnostics screen and hands it to Presentation as a plain `UIViewController`.
4. `Presentation/` is a folder inside the app target, so its isolation from `DataLayer` and `Flutter` is a convention, checked with:
   ```bash
   grep -rln "import DataLayer\|import Flutter" IoTGatewayApp/IoTGatewayApp/Presentation
   ```
   (no output expected).
5. Each layer owns its error vocabulary and translates at the boundary.

### Patterns

- **MVVM** with one `@Observable`, `@MainActor` ViewModel per screen. List and diagnostics screens model state as a single `ViewState` enum (`idle / loading / loaded / failed`). SwiftUI binds directly, UIKit binds through `withObservationTracking`.
- **Coordinator** owns navigation (list → detail → diagnostics). Screens expose closures and never push each other.
- **Screen factory** assembles each screen and view model when needed, keeping construction details out of the coordinator.
- **Composition root** (`AppDependencies`) builds the graph bottom-up with constructor injection. There are no singletons and no service locator.
- **Transport seam:** repositories depend on the `IoTTransport` protocol (bytes in, bytes out). Flutter is one implementation, a mock implementation is used in tests.

### Screens

| # | Screen | Technology | Notes |
|---|---|---|---|
| 1 | Gateway & device list | UIKit (`UICollectionView` list layout, diffable data source) | Online status, battery, signal bars, pull to refresh |
| 2 | Device telemetry & control | SwiftUI via `UIHostingController` | Metrics, polled every 3s, power toggle and target-temperature slider (HVAC), sampling-rate stepper (all devices) |
| 3 | Bridge diagnostics | UIKit container with an embedded `FlutterViewController` | Native bridge status and message count plus a Flutter-rendered message log |

Navigation is sequential: list → tap a device → detail → "Bridge diagnostics".

The optional fourth screen (settings and thresholds) is not implemented.

---

## 4. Data flow

Every user action follows the same path. Example: set device `XYZ1001` to a 5 second sampling rate.

1. **User action:** the stepper and Apply button in `DeviceDetailView`.
2. **ViewModel to Domain:** `DeviceDetailViewModel.applySamplingRate()` calls `UpdateSamplingRateUseCase.execute(deviceId: "XYZ1001", rate: 5)`.
3. **Domain to Data:** the use case validates the rule (rate must be 1 to 60) and calls `DeviceRepository.updateSamplingRate`, a protocol defined in Domain.
4. **Data to Flutter:** `DeviceRepositoryImpl` builds the JSON request envelope, and `FlutterChannelTransport` sends it through the `FlutterMethodChannel`.
5. **Flutter handling:** `BridgeHandler` decodes the request and delegates to `BridgeDispatcher`. `DeviceSimulator` mutates its in-memory device state, and a JSON response is returned.
6. **Propagation:** `BridgeClient` decodes the response, a mapper converts the DTO into a Domain entity, and the result returns through the use case to the ViewModel.
7. **UI update:** the ViewModel updates its observable state and SwiftUI re-renders.

Failures travel the same path in reverse.

---

## 5. Bridge documentation

### Channel

| Item | Value |
|---|---|
| Channel type | `FlutterMethodChannel` (standard codec) |
| Channel name | `com.lloyd.iot/commands` |
| Method name | `rpc` (the only method, the request payload carries the real method name) |
| Direction | Swift calls Dart, Dart replies |
| Payload | A JSON **string** in both directions |

The constants live in `Packages/DataLayer/Sources/DataLayer/Bridge/BridgeContract.swift` (Swift) and `flutter_iot_module/lib/main.dart` (Dart).

### Request envelope

```json
{
  "requestId": "6F36758C-1D2D-4388-83A4-B2A7C0D1A3FD",
  "method": "device.setSamplingRate",
  "params": { "deviceId": "XYZ1001", "rateSeconds": 5 }
}
```

### Success response envelope

```json
{
  "requestId": "6F36758C-1D2D-4388-83A4-B2A7C0D1A3FD",
  "data": { "deviceId": "XYZ1001", "appliedRateSeconds": 5 }
}
```

`requestId` is echoed back, and the Swift side rejects a reply whose id does not match.

### Methods

| Method | Params | `data` in the response |
|---|---|---|
| `bridge.status` | none | `{ "status": "ready", "messageCount": Int }` |
| `devices.list` | none | `{ "devices": [Device] }` |
| `device.get` | `{ "deviceId": String }` | `{ "device": Device }` |
| `device.sendCommand` | `{ "deviceId": String, "command": "setPower" \| "setTargetTemperature", "value": Bool \| Number }` | `{ "device": Device }` (the updated device) |
| `device.setSamplingRate` | `{ "deviceId": String, "rateSeconds": Int }` | `{ "deviceId": String, "appliedRateSeconds": Int }` |

### Device payload

```json
{
  "id": "XYZ1001",
  "name": "Living Room HVAC",
  "kind": "hvac",
  "connection": "online",
  "batteryPercent": null,
  "signalDbm": -52,
  "samplingRateSeconds": 10,
  "isPoweredOn": true,
  "targetTemperature": 22.0,
  "metrics": [
    { "kind": "temperature", "value": 23.4, "unit": "°C" },
    { "kind": "powerConsumption", "value": 1.2, "unit": "kW" }
  ]
}
```

| Field | Values |
|---|---|
| `kind` | `hvac`, `tempHumidity`, `gateway` |
| `connection` | `online`, `offline` |
| `metrics[].kind` | `temperature`, `humidity`, `powerConsumption` |
| `batteryPercent`, `targetTemperature` | `null` when not applicable |

An unknown enum value fails mapping and surfaces as `DomainError.unknown`, rather than being silently displayed wrongly.

### Simulated backend

| Device | Kind | State |
|---|---|---|
| `XYZ1001` Living Room HVAC | hvac | online |
| `XYZ1002` Bedroom Sensor | tempHumidity | online, battery 12% |
| `XYZ1003` Garage Sensor | tempHumidity | **offline** (used to demonstrate error handling) |
| `GW1000` Main Gateway | gateway | online |

The Dart `DeviceSimulator` keeps device state in memory, so a command changes what later reads return. Readings drift slightly on each read (an HVAC that is on drifts toward its target temperature). Every request is delayed by 150 ms to behave like a real device. Seed data is mock JSON in `flutter_iot_module/lib/simulator/seed_devices.dart`.

---

## 6. Testing

| Suite | Location | What it covers | Run with |
|---|---|---|---|
| Domain | `Packages/Domain/Tests` | Use case rules: rate range, offline rejection, target-temperature limits and device kind, signal bars | `cd Packages/Domain && swift test` |
| DataLayer | `Packages/DataLayer/Tests` | DTO to entity mapping, request payloads, error mapping, using a mock transport (no Flutter engine needed) | `cd Packages/DataLayer && swift test` |
| Dart | `flutter_iot_module/test` | Diagnostics display and bridge log entries | `cd flutter_iot_module && flutter test` |

---
