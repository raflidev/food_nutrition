# 📋 The Living Lab — Project Planning & Reference

> **Dokumen ini** adalah breakdown lengkap dari semua referensi desain di folder `docs/`, pemetaan ke kriteria submission Dicoding, serta roadmap implementasi ke Flutter.

---

## 1. Ringkasan Proyek

| | |
|---|---|
| **Nama Aplikasi** | The Living Lab |
| **Platform** | Flutter (Mobile-first) |
| **Deskripsi** | Aplikasi pelacak nutrisi makanan berbasis AI. User foto makanan → diidentifikasi oleh TFLite model → detail nutrisi dari Gemini API + resep dari MealDB API |
| **Submission** | Dicoding — Flutter Expert: Machine Learning |
| **Target Nilai** | **4 pts (Advanced)** di setiap kriteria |
| **Status** | Proyek Flutter masih default counter app |

---

## 2. Pemetaan Kriteria Submission → Fitur

### Kriteria 1: Pengambilan Gambar (Target: 4 pts — Advanced)

| Level | Requirement | Fitur yang Dibuat |
|---|---|---|
| **Basic (2)** | `image_picker` untuk ambil dari kamera/galeri | Tombol pick image + preview |
| **Skilled (3)** | + `image_cropper` untuk crop gambar | Crop screen setelah pick |
| **Advanced (4)** | + `camera` library untuk camera stream/feed | Custom camera dengan live preview + viewfinder overlay |

**Screen terkait:** [Capture Food](#33-📸-capture-food-camera)

**Package yang dibutuhkan:**
- [`image_picker`](https://pub.dev/packages/image_picker)
- [`image_cropper`](https://pub.dev/packages/image_cropper)
- [`camera`](https://pub.dev/packages/camera)

---

### Kriteria 2: Machine Learning (Target: 4 pts — Advanced)

| Level | Requirement | Fitur yang Dibuat |
|---|---|---|
| **Basic (2)** | TFLite food classifier + LiteRT framework | Load model → inferensi setelah gambar diambil |
| **Skilled (3)** | + `Isolate` untuk background inference | Inferensi di background thread, UI tidak freeze |
| **Advanced (4)** | + Firebase ML untuk cloud model storage | Upload model ke Firebase → download dinamis di app |

**Model:** [Google AIY Vision Food Classifier V1](https://www.kaggle.com/models/google/aiy/tfLite/vision-classifier-food-v1) (TFLite)

**Package yang dibutuhkan:**
- [`tflite_flutter`](https://pub.dev/packages/tflite_flutter) — LiteRT/TFLite runtime
- [`firebase_core`](https://pub.dev/packages/firebase_core) — Firebase setup
- [`firebase_ml_model_downloader`](https://pub.dev/packages/firebase_ml_model_downloader) — Dynamic model download
- Dart `Isolate` (built-in)

**Flow Inferensi:**
```
Gambar diambil
  → (Opsional) Crop
  → Preprocess (resize, normalize)
  → Kirim ke Isolate
  → TFLite inference di background
  → Return: {foodName, confidenceScore}
  → Tampilkan di halaman prediksi
```

---

### Kriteria 3: Halaman Prediksi (Target: 4 pts — Advanced)

| Level | Requirement | Fitur yang Dibuat |
|---|---|---|
| **Basic (2)** | Halaman detail + foto + nama makanan + confidence score | Analysis Result page |
| **Skilled (3)** | + Data dari MealDB API (nama, foto, bahan, instruksi) | Section MealDB reference |
| **Advanced (4)** | + Nutrisi dari Gemini API (kalori, karbo, lemak, serat, protein) | Section nutrisi dari Gemini |

**Screen terkait:** [Analysis Result](#34-🔬-analysis-result)

**API Endpoints:**
- **MealDB:** `https://www.themealdb.com/api/json/v1/1/search.php?s={foodName}`
  - Response: `strMeal`, `strMealThumb`, `strIngredient1-20`, `strMeasure1-20`, `strInstructions`
- **Gemini AI:** Google Generative AI API
  - Prompt: *"Berikan informasi nutrisi untuk [foodName]: kalori, karbohidrat, lemak, serat, protein"*

**Package yang dibutuhkan:**
- [`dio`](https://pub.dev/packages/dio) atau `http` — REST API calls
- [`google_generative_ai`](https://pub.dev/packages/google_generative_ai) — Gemini API

---

## 3. Referensi Desain (Breakdown dari `docs/`)

### 3.1 Design System — "The Living Lab"

> File: [`vitality_core/DESIGN.md`](./vitality_core/DESIGN.md)

**Filosofi:** "Organic Asymmetry" & "Tonal Depth" — premium wellness magazine feel.

**Warna Utama:**

| Token | Hex | Fungsi |
|---|---|---|
| `primary` | `#006a28` | Brand, CTA utama |
| `primary-container` | `#5cfd80` | Background energik |
| `surface` | `#f5f7f5` | Canvas utama |
| `on-surface` | `#2c2f2e` | Teks utama |
| `tertiary` | `#00656f` | Aksen sekunder |

**Typography:** Manrope (headlines) + Plus Jakarta Sans (body)

**Aturan Kunci:**
- ❌ No `1px border` untuk section separator → gunakan background color shifts
- ❌ No `#000000` → selalu `on-surface`
- ✅ Glassmorphism (80% opacity + blur 20px) untuk header/navbar
- ✅ Gradient `primary` → `primary-fixed-dim` (135°) untuk CTA

---

### 3.2 📊 Nutrition Dashboard (Home)

> [`nutrition_dashboard/code.html`](./nutrition_dashboard/code.html) | [`screen.png`](./nutrition_dashboard/screen.png)

**Komponen:**
1. **TopAppBar** — glassmorphism, profile + "The Living Lab" + notification
2. **Daily Energy Card** — 1,842 kcal, progress bar (goal 2,500), "Active Day"
3. **Macro Ring Cards** — Protein 75% (112g/150g), Carbs 50% (140g/280g)
4. **Detail Cards** — Fat, Fiber, Water dengan mini progress bar
5. **CTA Banner** — "Track Your Progress" + "Capture Meal" button
6. **Today's Timeline** — list makanan hari ini
7. **BottomNavBar** — Home (active) | Camera | History

---

### 3.3 📸 Capture Food (Camera)

> [`capture_food/code.html`](./capture_food/code.html) | [`screen.png`](./capture_food/screen.png)

**Komponen:**
1. **Camera viewfinder** — full screen live feed
2. **Scanning overlay** — corner brackets hijau + scan line animasi
3. **Feedback badge** — "Scanning... Poke Bowl detected"
4. **Floating cards** — Confidence 85% + Kcal ring (740)
5. **Mode selector** — Barcode / **AI Scan** / Manual
6. **Shutter controls** — Gallery, Shutter, Switch camera
7. **BottomNavBar** — Home | Camera (active) | History

---

### 3.4 🔬 Analysis Result

> [`analysis_result/code.html`](./analysis_result/code.html) | [`screen.png`](./analysis_result/screen.png)

**Komponen:**
1. **TopAppBar** — back, "Analysis Result", more
2. **Food image** — rounded + shadow
3. **AI badge** — "GEMINI AI ANALYZED"
4. **Food identity** — nama + deskripsi
5. **Total Energy** — circular ring (412 Kcal)
6. **Macro Bento Grid** — Protein, Karbo, Lemak, Serat
7. **Nutritional Details** — list lengkap per nutrient
8. **Lab Insight** — AI-generated insight card
9. **Action Footer** — "Edit Data" + "Add to Log"

---

### 3.5 📜 Meal History

> [`meal_history/code.html`](./meal_history/code.html) | [`screen.png`](./meal_history/screen.png)

**Komponen:**
1. **Page header** — "Meal History" + subtitle
2. **Day Groups** — sticky date header + total kcal
3. **Meal Cards** — thumbnail, meal type, nama, kcal, protein, chevron
4. **FAB** — tombol "+" untuk manual entry
5. **BottomNavBar** — Home | Camera | History (active)

---

## 4. Navigasi Aplikasi

```
┌──────────────────────────────────────────────┐
│               BottomNavBar                   │
│   [Home]        [Camera]        [History]    │
│  Dashboard     Capture Food   Meal History   │
└─────┬──────────────┬──────────────┬──────────┘
      │              │              │
      ▼              ▼              ▼
  Dashboard      Camera Screen   History List
      │              │
      │    ┌─────────┤
      │    ▼         ▼
      │  AI Scan   Pick/Crop
      │    │         │
      │    └────┬────┘
      │         ▼
      │   TFLite Inference (Isolate)
      │         │
      │         ▼
      │   Analysis Result Page
      │    ┌────┴────┐
      │    ▼         ▼
      │  MealDB    Gemini API
      │  (resep)   (nutrisi)
      │         │
      │         ▼
      └── "Add to Log" ──► History
```

---

## 5. Roadmap Implementasi (Per Phase)

### Phase 1: Foundation (Wajib Duluan)
- [ ] Setup folder structure (feature-based)
- [ ] Implementasi Design System → `ThemeData`, `ColorScheme`, typography
- [ ] Setup navigasi (`go_router`)
- [ ] Shared widgets: BottomNavBar, TopAppBar, ProgressRing, MealCard
- [ ] Integrasi Google Fonts

### Phase 2: Kriteria 1 — Image Capture
- [ ] **Basic:** `image_picker` — pick dari kamera + galeri, tampilkan preview
- [ ] **Skilled:** `image_cropper` — crop setelah pick
- [ ] **Advanced:** `camera` library — custom camera screen dengan viewfinder overlay + camera stream

### Phase 3: Kriteria 2 — Machine Learning
- [ ] Download model TFLite dari Kaggle
- [ ] **Basic:** Integrasi `tflite_flutter`, load model, jalankan inferensi
- [ ] **Skilled:** Pindahkan inferensi ke `Isolate` (background thread)
- [ ] **Advanced:** Setup Firebase project → upload model → `firebase_ml_model_downloader`

### Phase 4: Kriteria 3 — Halaman Prediksi
- [ ] **Basic:** Analysis Result page — foto, nama makanan, confidence score
- [ ] **Skilled:** Integrasi MealDB API — tampilkan resep, bahan, instruksi
- [ ] **Advanced:** Integrasi Gemini API — tampilkan nutrisi (kalori, karbo, lemak, serat, protein)

### Phase 5: Dashboard & History
- [ ] Nutrition Dashboard (Home) — daily summary, macro rings, timeline
- [ ] Meal History — list grouped by date
- [ ] Local storage untuk meal log (Hive/Drift)

### Phase 6: Polish
- [ ] Animasi & micro-interactions
- [ ] Error handling & loading states
- [ ] Testing

---

## 6. Tech Stack

| Kategori | Package | Versi/Note |
|---|---|---|
| **Framework** | Flutter | SDK ^3.11.1 |
| **Image Picker** | `image_picker` | Kamera + galeri |
| **Image Crop** | `image_cropper` | Crop UI |
| **Camera** | `camera` | Custom camera + stream |
| **TFLite** | `tflite_flutter` | LiteRT runtime |
| **Firebase** | `firebase_core` | Setup |
| **Firebase ML** | `firebase_ml_model_downloader` | Dynamic model |
| **HTTP** | `dio` | REST API calls |
| **Gemini** | `google_generative_ai` | Nutrisi AI |
| **Navigation** | `go_router` | Declarative routing |
| **State** | `flutter_riverpod` | Riverpod |
| **Local DB** | `hive` + `hive_flutter` | NoSQL local storage |
| **Fonts** | `google_fonts` | Manrope, Plus Jakarta Sans |

---

## 7. Struktur Folder

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_typography.dart
├── core/
│   ├── constants/
│   ├── utils/
│   │   └── image_utils.dart
│   └── widgets/
│       ├── bottom_nav_bar.dart
│       ├── top_app_bar.dart
│       ├── progress_ring.dart
│       └── meal_card.dart
├── features/
│   ├── capture/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── camera_page.dart       # Custom camera + viewfinder
│   │   │   │   └── image_picker_page.dart  # Gallery pick + crop
│   │   │   └── widgets/
│   │   └── data/
│   ├── analysis/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   └── analysis_result_page.dart
│   │   │   └── widgets/
│   │   │       ├── nutrition_card.dart
│   │   │       ├── mealdb_section.dart
│   │   │       └── gemini_nutrition_section.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── prediction_result.dart
│   │   │   │   ├── meal_info.dart       # MealDB model
│   │   │   │   └── nutrition_info.dart  # Gemini model
│   │   │   └── repositories/
│   │   └── data/
│   │       ├── mealdb_api.dart
│   │       └── gemini_service.dart
│   ├── dashboard/
│   │   └── presentation/pages/
│   │       └── dashboard_page.dart
│   └── history/
│       └── presentation/pages/
│           └── history_page.dart
└── services/
    ├── ml/
    │   ├── classifier_service.dart    # TFLite wrapper
    │   ├── inference_isolate.dart     # Isolate runner
    │   └── firebase_model_service.dart # Firebase ML downloader
    └── storage/
        └── meal_storage.dart
```

---

## 8. Model ML: Food Classifier

**Source:** [Google AIY Vision — Food Classifier V1](https://www.kaggle.com/models/google/aiy/tfLite/vision-classifier-food-v1)

**Spesifikasi:**
- Format: TensorFlow Lite (`.tflite`)
- Input: Image (biasanya 224x224 RGB)
- Output: Array probabilitas per kategori makanan
- Label: File label terpisah (mapping index → nama makanan)

**Preprocessing yang diperlukan:**
1. Resize gambar ke input size model
2. Normalize pixel values (0-1 atau -1 to 1, tergantung model)
3. Convert ke format tensor yang sesuai

**Catatan:** Test model dulu dengan sampel gambar sebelum integrasi ke Flutter!

---

## 9. API Reference

### MealDB API (Free, no key required)
```
GET https://www.themealdb.com/api/json/v1/1/search.php?s={foodName}
```
Response fields yang dibutuhkan:
- `strMeal` — Nama makanan
- `strMealThumb` — URL foto
- `strIngredient1` s/d `strIngredient20` — Bahan-bahan
- `strMeasure1` s/d `strMeasure20` — Takaran
- `strInstructions` — Langkah pembuatan

### Gemini API
```dart
final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
final prompt = 'Berikan informasi nutrisi untuk "$foodName" dalam format JSON: '
    '{"kalori": "...", "karbohidrat": "...", "lemak": "...", "serat": "...", "protein": "..."}';
```

> [!NOTE]
> Submission menyebutkan: "Tidak harus menyematkan API Key pada project." — bisa pakai environment variable atau input field.

---

## 10. Keputusan Teknis yang Perlu Ditentukan

| # | Keputusan | Pilihan | Status |
|---|---|---|---|
| 1 | State Management | **Riverpod** | ✅ Confirmed |
| 2 | Local Database | **Hive** | ✅ Confirmed |
| 3 | Gemini API Key | User input / env variable | TBD |
| 4 | Firebase setup | Android (minimum) | TBD |

---

*Terakhir di-update: 2026-03-19*
