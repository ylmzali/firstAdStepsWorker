# Toplu Konum Gönderimi API Dokümantasyonu

## Endpoint
```
POST /trackbulkroutelocation
```

## Açıklama
Bu endpoint, çalışanların rota takibi sırasında toplanan konum verilerini toplu olarak göndermek için kullanılır. Konumlar her 5 saniyede bir toplanır ve 30 saniyede bir veya buffer dolduğunda (maksimum 15 konum) gönderilir.

## Request Headers
```
Content-Type: application/json
app_token: cd786d6d-daf7-4e3f-bff2-24c144c9f013
```

## Request Body

### Ana Yapı
```json
{
  "route_id": "string",
  "assigned_plan_id": "string",
  "assigned_screen_id": "string",
  "assigned_employee_id": "string",
  "assigned_schedule_id": "string",
  "session_date": "string",
  "actual_start_time": "number",
  "actual_end_time": "number",
  "status": "string",
  "battery_level": "number",
  "signal_strength": "number",
  "actual_duration_min": "number",
  "locations": [
    // Konum dizisi
  ]
}
```

### Konum Noktası (LocationPoint)
```json
{
  "latitude": 41.00137470763681,
  "longitude": 28.509625313613412,
  "accuracy": 12.830529032814193,
  "timestamp": 775737066.569455,
  "speed": -1,
  "heading": -1,
  "distance_from_previous": 0,
  "total_distance": 0
}
```

## Alan Açıklamaları

### Ana Alanlar
- `route_id`: Rota ID'si
- `assigned_plan_id`: Atanan plan ID'si
- `assigned_screen_id`: Atanan ekran ID'si
- `assigned_employee_id`: Atanan çalışan ID'si
- `assigned_schedule_id`: Atanan program ID'si
- `session_date`: Oturum tarihi
- `actual_start_time`: Gerçek başlangıç zamanı
- `actual_end_time`: Gerçek bitiş zamanı
- `status`: Durum ("active", "paused", "completed")
- `battery_level`: Batarya seviyesi
- `signal_strength`: Sinyal gücü
- `actual_duration_min`: Gerçek süre (dakika)
- `locations`: Konum noktaları dizisi (maksimum 15 adet)

### Konum Noktası Alanları
- `latitude`: Enlem (double)
- `longitude`: Boylam (double)
- `accuracy`: Konum hassasiyeti (metre)
- `timestamp`: Konum alınma zamanı (timestamp)
- `speed`: Hız (m/s, -1 = bilinmiyor)
- `heading`: Yön (derece, -1 = bilinmiyor)
- `distance_from_previous`: Önceki konumdan mesafe (metre)
- `total_distance`: Toplam kat edilen mesafe (metre)

## Response

### Başarılı Yanıt (200)
```json
{
  "status": "success",
  "message": "Bulk location data saved successfully",
  "data": {
    "saved_locations_count": 15,
    "route_id": "route_123",
    "employee_id": "emp_456"
  }
}
```

### Hata Yanıtı (400/500)
```json
{
  "status": "error",
  "message": "Error message",
  "error_code": "VALIDATION_ERROR"
}
```

## Örnek Kullanım

### cURL
```bash
curl -X POST https://buisyurur.com/workersapi/trackbulkroutelocation \
  -H "Content-Type: application/json" \
  -H "app_token: cd786d6d-daf7-4e3f-bff2-24c144c9f013" \
  -d @bulk_location_example.json
```

### JavaScript
```javascript
const response = await fetch('https://buisyurur.com/workersapi/trackbulkroutelocation', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'app_token': 'cd786d6d-daf7-4e3f-bff2-24c144c9f013'
  },
  body: JSON.stringify(bulkLocationData)
});

const result = await response.json();
```

## Performans Özellikleri

### Buffer Yönetimi
- Konumlar her 5 saniyede bir toplanır
- Akıllı gruplandırma ile benzer konumlar birleştirilir
- Maksimum 15 konum buffer'da tutulur
- 30 saniyede bir otomatik gönderim
- Buffer dolduğunda hemen gönderim
- Hata durumunda konumlar tekrar buffer'a eklenir

### Akıllı Gruplandırma
- **Mesafe Kontrolü**: 10 metre içindeki konumlar gruplandırılır
- **Zaman Kontrolü**: 60 saniye içindeki konumlar gruplandırılır
- **Hareket Durumu**: Durma/hareket geçişleri ayrı gruplar
- **Yön Değişimi**: 45° üzeri yön değişimleri ayrı gruplar
- **Hassasiyet**: 50m üzeri düşük hassasiyet ayrı gruplar

### Akıllı Filtreleme
- Mesafe bazlı filtreleme (minimum 3 metre)
- Yön değişimi kontrolü (minimum 15 derece)
- Hız değişimi kontrolü (minimum 2 m/s)
- Hassasiyet kontrolü (maksimum 20 metre)

### Offline Desteği
- İnternet yoksa konumlar local'de saklanır
- Bağlantı geldiğinde otomatik gönderim
- Veri kaybı önleme

## Güvenlik

### Doğrulama
- app_token header'ı zorunlu
- Tüm alanlar için tip kontrolü
- Tarih formatı doğrulaması
- Koordinat aralığı kontrolü

### Rate Limiting
- Maksimum 100 request/dakika
- IP bazlı kısıtlama
- Token bazlı kısıtlama

## Hata Kodları

| Kod | Açıklama |
|-----|----------|
| `VALIDATION_ERROR` | Geçersiz veri formatı |
| `INVALID_TOKEN` | Geçersiz app_token |
| `ROUTE_NOT_FOUND` | Rota bulunamadı |
| `EMPLOYEE_NOT_FOUND` | Çalışan bulunamadı |
| `ASSIGNMENT_NOT_FOUND` | Görev bulunamadı |
| `RATE_LIMIT_EXCEEDED` | Rate limit aşıldı |
| `INTERNAL_ERROR` | Sunucu hatası |

## Veritabanı Yapısı

### locations Tablosu
```sql
CREATE TABLE bulk_locations (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  route_id VARCHAR(255) NOT NULL,
  employee_id VARCHAR(255) NOT NULL,
  assignment_id VARCHAR(255) NOT NULL,
  latitude DOUBLE NOT NULL,
  longitude DOUBLE NOT NULL,
  accuracy DOUBLE,
  timestamp DATETIME NOT NULL,
  speed DOUBLE,
  heading DOUBLE,
  battery_level DOUBLE,
  signal_strength INT,
  distance_from_previous DOUBLE,
  total_distance DOUBLE,
  session_date DATETIME,
  actual_start_time DATETIME,
  actual_end_time DATETIME,
  status VARCHAR(50),
  actual_duration_min INT,
  assigned_plan_id VARCHAR(255),
  assigned_screen_id VARCHAR(255),
  assigned_schedule_id VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_route_employee (route_id, employee_id),
  INDEX idx_timestamp (timestamp),
  INDEX idx_assignment (assignment_id)
);
```

## Monitoring ve Logging

### Log Alanları
- Request timestamp
- Employee ID
- Route ID
- Konum sayısı
- Response time
- Status code
- Error details

### Metrics
- Günlük/haftalık/aylık konum sayısı
- Ortalama response time
- Error rate
- Buffer utilization
- Offline/online ratio
