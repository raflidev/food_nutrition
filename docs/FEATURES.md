# 📦 Feature Documentation — The Living Lab

> Dokumen ini mencatat semua fitur dan perbaikan yang ditambahkan setelah initial planning.
> Diurutkan berdasarkan area fitur, bukan urutan kronologis.

---

## 1. 🎯 Confidence Threshold — Tidak Simpan Jika Confidence < 10%

**File:** `lib/features/analysis/presentation/pages/analysis_result_page.dart`

### Deskripsi
Jika model TFLite mengembalikan confidence score di bawah 10%, tombol "Simpan ke Riwayat" tidak ditampilkan dan user diberikan peringatan visual.

### Implementasi
- Tombol sticky (Save to Log) hanya muncul jika `prediction.confidence >= 0.1`
- Jika confidence < 10%, widget `_buildLowConfidenceBanner()` ditampilkan — berisi pesan orange warning
- Logika di `_saveToLog`: hanya dipanggil saat confidence cukup, mencegah data tidak akurat masuk riwayat

### Alasan
Data nutrisi dari makanan yang tidak teridentifikasi dengan baik akan menyesatkan user. Threshold 10% menjadi filter minimum keandalan model.

---

## 2. 📸 Perbaikan Kamera

**File:** `lib/features/capture/presentation/pages/camera_page.dart`

### 2a. Fix: Kamera Force Close (Open Count: 1 / Max: 1)

**Masalah:** Kamera crash saat membuka kembali halaman — `CameraException: Open count: 1 (Max allowed: 1)`.

**Penyebab:** Controller lama di-dispose *setelah* controller baru diinisialisasi, menyebabkan 2 kamera aktif sekaligus.

**Solusi:** Di `_setupCameraController`, dispose dan null-kan controller lama *sebelum* membuat controller baru:
```dart
if (_controller != null) {
  await _controller!.dispose();
  _controller = null;
}
// baru buat controller baru
```

### 2b. Fix: Kamera Loading Selamanya Saat Kembali dari Halaman Analisis

**Masalah:** Setelah navigasi ke halaman analisis dan kembali, kamera tidak tampil (loading terus).

**Penyebab:** `didChangeAppLifecycleState` men-dispose kamera saat state `inactive`, padahal `inactive` terpicu saat navigasi biasa (bukan app ke background).

**Solusi:** Hanya dispose saat state `paused`, bukan `inactive`:
```dart
if (state == AppLifecycleState.paused) {
  await _controller?.dispose();
} else if (state == AppLifecycleState.resumed) {
  // re-init
}
```

**Tambahan:** Safety re-init di `build` via `addPostFrameCallback` jika `_isInit = false`.

### 2c. Penghapusan Fitur Tidak Perlu

- Dihapus: Tombol **Gallery** (image_picker dari kamera)
- Dihapus: Badge **"Ready to Scan"** — terlalu noisy, tidak menambah value
- Bottom bar sekarang hanya menampilkan tombol **Shutter** di tengah

---

## 3. ⚠️ Gemini Error Handling — Pesan Error Detail

**File:** `lib/services/api/gemini_service.dart`

### Deskripsi
Sebelumnya, semua error Gemini ditangkap secara senyap (silent) dan mengembalikan `null`. Sekarang setiap tipe error diidentifikasi dan dilempar sebagai `GeminiException` dengan pesan yang informatif.

### Klasifikasi Error

| Kondisi | Pesan ke User |
|---|---|
| `SocketException` | "Tidak ada koneksi internet. Periksa jaringan Anda." |
| API Key tidak valid / `UNAUTHENTICATED` | "API Key Gemini tidak valid. Periksa kembali API Key Anda." |
| Quota habis / `RESOURCE_EXHAUSTED` | "Kuota Gemini API habis. Coba lagi nanti." |
| `PERMISSION_DENIED` | "Akses Gemini API ditolak. Pastikan API Key memiliki izin yang benar." |
| Model tidak ditemukan | "Model Gemini tidak ditemukan. Hubungi pengembang." |
| Timeout / `DEADLINE_EXCEEDED` | "Permintaan ke Gemini timeout. Coba lagi." |
| Server error / `UNAVAILABLE` | "Server Gemini sedang bermasalah. Coba lagi nanti." |

### Kelas `GeminiException`
```dart
class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);
}
```

---

## 4. 🛡️ Graceful Degradation — Tetap Tampilkan MealDB Saat Gemini Gagal

**File:** `lib/features/analysis/presentation/providers/analysis_provider.dart`

### Deskripsi
Jika Gemini gagal, halaman analisis tetap menampilkan data MealDB (resep, bahan, instruksi) alih-alih blank page.

### Implementasi
- Diganti dari `Future.wait([gemini, mealdb])` ke dua `try-catch` independen
- Field `geminiError` ditambahkan ke `AnalysisState`
- Jika Gemini error, `geminiError` diisi pesan error, `nutritionInfo` tetap `null`
- Halaman menampilkan banner orange: `_buildGeminiErrorBanner(geminiError)`

### Kondisi Banner
- **Banner Orange (Gemini error):** Gemini gagal, tapi MealDB berhasil
- **Banner Abu (MealDB null):** MealDB tidak punya data untuk makanan tersebut
- **Normal:** Semua berhasil

---

## 5. ✅ Verifikasi Gemini API Key di Dashboard

**File:** `lib/features/dashboard/presentation/providers/gemini_status_provider.dart`

### Deskripsi
Dashboard menampilkan status koneksi Gemini secara real-time dengan melakukan test call aktual (bukan hanya cek apakah API key tidak kosong).

### Status yang Ditampilkan

| Status | Icon | Warna |
|---|---|---|
| Loading | `hourglass_empty` | Abu-abu |
| Ready | `check_circle_outline` | Hijau (primary) |
| Network Error | `wifi_off_outlined` | Orange |
| API Key Invalid | `vpn_key_off_outlined` | Merah |
| No Key | `key_off_outlined` | Merah |
| Unknown Error | `warning_amber_outlined` | Merah |

### Implementasi
```dart
final geminiStatusProvider = FutureProvider<GeminiStatusInfo>((ref) async {
  // Buat instance GenerativeModel dan kirim prompt pendek
  // Return GeminiStatusInfo berdasarkan response / exception
});
```

---

## 6. 📖 Read More — Instruksi Resep

**File:** `lib/features/analysis/presentation/pages/analysis_result_page.dart`

### Deskripsi
Instruksi cara memasak dari MealDB seringkali panjang. Ditambahkan toggle "Baca Selengkapnya / Sembunyikan" agar tampilan tetap rapi.

### Implementasi
- State: `bool _showFullInstructions = false`
- Jika `!_showFullInstructions`: teks dibatasi 3 baris (`maxLines: 3, overflow: TextOverflow.ellipsis`)
- Tombol teks di bawah untuk toggle

---

## 7. 📋 History Detail Page

**File:** `lib/features/history/presentation/pages/history_detail_page.dart`

**Route:** `/history/detail` (di luar `ShellRoute`, sehingga tidak ada BottomNavBar)

### Deskripsi
Halaman detail untuk setiap meal log di riwayat — menampilkan semua data yang tersimpan tanpa memanggil API lagi.

### Komponen Utama
1. **Header** — Foto makanan (dari path lokal), nama, confidence score
2. **Stored Nutrition Section** — Data nutrisi tersimpan (5 fields): Kalori, Protein, Karbohidrat, Lemak, Serat
3. **Generate Nutrition Button** — Muncul jika semua nilai nutrisi = 0, memungkinkan user generate ulang via Gemini
4. **Recipe Section** — Data MealDB: thumbnail, kategori, bahan, instruksi (dengan read-more toggle)
5. **Saved On Bar** — Sticky bottom bar menampilkan tanggal simpan

### Aturan API
- **TIDAK pernah** memanggil Gemini
- **Boleh** memanggil MealDB hanya jika cache lokal kosong
- Data dimuat dari `MealExtrasStorageService` terlebih dahulu

---

## 8. 💾 Local Extras Cache (`meal_extras` Hive Box)

**File:** `lib/services/storage/meal_extras_storage.dart`

### Deskripsi
Hive box terpisah (`meal_extras`) untuk menyimpan data `NutritionInfo` dan `MealInfo` per meal ID sebagai JSON string. Ini memungkinkan history detail page menampilkan semua data tanpa hit API.

### API
```dart
class MealExtrasStorageService {
  Future<void> init();
  Future<void> saveExtras(String mealId, NutritionInfo? nutrition, MealInfo? meal);
  ({NutritionInfo? nutrition, MealInfo? meal}) loadExtras(String mealId);
  Future<void> deleteExtras(String mealId);
}
```

### Key Storage
- `nutrition_{mealId}` → JSON string NutritionInfo
- `meal_{mealId}` → JSON string MealInfo

### Inisialisasi
Di `main.dart`, `MealExtrasStorageService().init()` dipanggil setelah `Hive.initFlutter()`.

---

## 9. 🧬 Extended MealLog Model — 5 Nutrition Fields

**File:** `lib/features/history/domain/models/meal_log.dart`

### Deskripsi
Model `MealLog` diperluas dari 2 field nutrisi (calories, protein) menjadi 5 field lengkap.

### Field Baru
| Field | Tipe | Default |
|---|---|---|
| `carbohydrates` | `int` | `0` |
| `fat` | `int` | `0` |
| `fiber` | `int` | `0` |

### Backward Compatibility
Hive TypeAdapter menggunakan `try-catch` saat membaca field baru agar data lama (yang belum punya 3 field ini) tidak crash:
```dart
try {
  carbohydrates = reader.readInt();
  fat = reader.readInt();
  fiber = reader.readInt();
} catch (_) {
  // data lama — default 0
}
```

---

## 10. 🔄 Generate Ulang Nutrisi di History Detail

**File:** `lib/features/history/presentation/pages/history_detail_page.dart`

### Deskripsi
Jika semua nilai nutrisi tersimpan = 0 (data kosong), user dapat meng-generate ulang menggunakan Gemini API langsung dari halaman detail.

### Alur
1. User tap tombol "Generate Nutrisi"
2. App memanggil Gemini API dengan nama makanan dari label prediksi
3. Hasil disimpan ke Hive (`meal_storage`) + extras cache (`meal_extras`)
4. `historyProvider` di-invalidate agar data fresh
5. UI diperbarui via `_updatedMeal` local state (tanpa navigate away)

### Kondisi
- Tombol hanya muncul jika `calories == 0 && protein == 0`
- Loading state ditampilkan saat generate berlangsung
- Error ditampilkan via `_nutritionError` state

---

## 11. 📅 Calendar Filter di History Page

**File:** `lib/features/history/presentation/pages/history_page.dart`

### Deskripsi
User dapat memfilter riwayat makanan berdasarkan tanggal menggunakan custom calendar picker (tanpa package eksternal).

### Komponen
- **Calendar Icon Button** — Di AppBar, aktif (background primary) jika ada filter
- **Filter Chip** — Ditampilkan di bawah AppBar saat filter aktif, tap untuk hapus filter
- **`_CalendarBottomSheet`** — Modal bottom sheet dengan kalender bulanan kustom

### Fitur Calendar
- Navigasi bulan (prev/next)
- Dot indicator (hijau) pada tanggal yang memiliki meal log
- Highlight tanggal yang dipilih
- Highlight tanggal hari ini
- Tombol "Tampilkan Semua" untuk clear filter

### Implementasi
```dart
// Konversi ke ConsumerStatefulWidget
DateTime? _selectedDate;

// Filter logic
final filtered = selectedDate != null
  ? meals.where((m) => _isSameDay(m.date, selectedDate!))
  : meals;
```

---

## 12. 🔍 MealDB Multi-Strategy Search

**File:** `lib/services/api/mealdb_api.dart`

### Deskripsi
Pencarian MealDB menggunakan beberapa strategi fallback agar lebih banyak makanan yang cocok (label dari model ML sering tidak persis nama di MealDB).

### Strategi (dieksekusi berurutan, berhenti saat ada hasil)
1. Nama lengkap asli (e.g., `"Chicken Tikka Masala"`)
2. Kata pertama (e.g., `"Chicken"`)
3. Dua kata pertama (e.g., `"Chicken Tikka"`)
4. Kata terakhir (e.g., `"Masala"`)

### Catatan
Query dideduplikasi sebelum iterasi. Hasil pertama yang ditemukan langsung dikembalikan.

---

## 13. 🧹 Cleanup: `deleteExtras` di History Provider

**File:** `lib/features/history/presentation/providers/history_provider.dart`

### Deskripsi
Saat user menghapus meal log, extras cache untuk meal tersebut juga dihapus agar tidak ada orphaned data.

```dart
Future<void> deleteMeal(String id) async {
  await _storage.deleteMeal(id);
  await MealExtrasStorageService().deleteExtras(id); // cleanup cache
  state = AsyncData(state.value!..removeWhere((m) => m.id == id));
}
```

---

*Terakhir di-update: 2026-03-29*
