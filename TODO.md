# Project Reconstruction Checklist

This document outlines the steps to recreate the **PropFi** project from scratch, including Smart Contracts (Aiken), Offchain Logic (MeshJS), and Frontend (Flutter).

## Phase 1: Environment Setup
- [ ] **Install Prerequisites**
    - [ ] Install [Aiken](https://aiken-lang.org/installation) (v1.1.0+)
    - [ ] Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.22.0+)
    - [ ] Install [Node.js](https://nodejs.org/) (v20+) & npm
    - [ ] Install VS Code with extensions: Aiken, Flutter, Prettier

## Phase 2: Smart Contracts (Aiken)
- [ ] **Initialize Project**
    ```bash
    mkdir -p contracts
    cd contracts
    aiken new propfi/contracts
    ```
- [ ] **Configure Dependencies** (`aiken.toml`)
    - [ ] Add `aiken-lang/stdlib` (v2.0.0+)
- [ ] **Implement Validators**
    - [ ] Create `lib/propfi/types.ak` (Define Datum/Redeemer types)
    - [ ] Create `validators/fractionalize.ak` (Main logic)
- [ ] **Build & Test**
    - [ ] Run `aiken build` (Generates `plutus.json`)
    - [ ] Run `aiken check` (Run tests)

## Phase 3: Offchain SDK (TypeScript + MeshJS)
- [ ] **Initialize Project**
    ```bash
    mkdir -p offchain
    cd offchain
    npm init -y
    npm install typescript ts-node @types/node --save-dev
    npx tsc --init
    ```
- [ ] **Install Dependencies**
    - [ ] `npm install @meshsdk/core`
- [ ] **Implement Logic** (`src/`)
    - [ ] `transaction_builder.ts`: Functions to build transactions using Mesh.
    - [ ] `deploy.ts`: Script to deploy compiled contracts.
    - [ ] `browser_entry.ts`: Entry point for browser bundling (for Flutter interop).
- [ ] **Build Bundle**
    - [ ] Configure webpack/esbuild to bundle `browser_entry.ts` into a single JS file for the frontend.

## Phase 4: Frontend (Flutter)
- [ ] **Initialize Project**
    ```bash
    flutter create frontend
    cd frontend
    ```
- [ ] **Add Dependencies** (`pubspec.yaml`)
    - [ ] `provider` (State management)
    - [ ] `google_fonts` (Typography)
    - [ ] `url_launcher` (External links)
    - [ ] `pdf` (Certificate generation)
- [ ] **Setup JS Interop**
    - [ ] Copy the bundled JS from Phase 3 to `frontend/web/js/offchain.js`.
    - [ ] Add `<script src="js/offchain.js"></script>` to `frontend/web/index.html`.
    - [ ] Create `lib/services/js_stub.dart` and `js_util_web.dart` to call JS functions from Dart.
- [ ] **Implement Features** (`lib/features/`)
    - [ ] **Auth**: `auth_landing_page.dart`, `setup_profile_page.dart`
    - [ ] **Marketplace**: `marketplace_page.dart`, `property_card.dart`
    - [ ] **Portfolio**: `portfolio_page.dart`
    - [ ] **Admin**: `admin_page.dart` (Minting/Management)

## Phase 5: Integration & Deployment
- [ ] **Deploy Contracts**
    - [ ] Run offchain deploy script to get Policy IDs and Validator Addresses.
    - [ ] Update frontend constants with new Contract IDs.
- [ ] **Run Application**
    - [ ] `cd frontend && flutter run -d chrome`

## Phase 6: Hydra Layer 2 Integration ✅ COMPLETED
- [x] **Setup Hydra Node in WSL**
    - [x] Create `hydra-node-setup.sh` script
    - [x] Download and configure Hydra node binary
    - [x] Generate cryptographic keys
- [x] **Configure Windows Integration**
    - [x] Create `setup-hydra-port-forwarding.ps1` script
    - [x] Setup port forwarding from Windows to WSL
    - [x] Configure Windows Firewall rules
- [x] **Implement Dart/Flutter Integration**
    - [x] Update `HydraService` with full WebSocket support
    - [x] Add transaction submission to L2
    - [x] Integrate with `CertificateService`
    - [x] Create `HydraStatusWidget` UI component
- [x] **Create Documentation & Tools**
    - [x] `HYDRA_SETUP.md` - Full setup guide
    - [x] `HYDRA_CHECKLIST.md` - Quick checklist
    - [x] `start-hydra.ps1` - One-click start script
    - [x] `hydra-test.html` - Connection test page

**Get Started**: See `HYDRA_CHECKLIST.md` or run `.\start-hydra.ps1`

## Phase 7: Midnight Integration (Optional/Advanced)
- [ ] **Setup Midnight**
    - [ ] Initialize `midnight/` directory.
    - [ ] Write `contracts/private_bid.ts` (Compact language).