import Foundation

enum LegalContent {
    static let privacyPolicySections: [LegalSection] = [
        LegalSection(
            heading: "1. Veri sorumlusu ve kapsam",
            paragraphs: [
                "Bu politika, Nöbetçim iOS uygulaması ve nobetcim.info alan adı altındaki hizmetler için geçerlidir. Platform; yerel hizmet ve işletme bilgilerine (bugün ağırlıklı olarak nöbetçi eczaneler) erişimi kolaylaştırmayı amaçlar."
            ]
        ),
        LegalSection(
            heading: "2. Toplanan veriler ve amaçlar",
            bullets: [
                "Cihazda saklanan veriler: Son kullanılan il ve ilçe seçimleri ile günlük liste önbelleği yalnızca cihazınızda tutulur; kullanıcı hesabı oluşturulmaz.",
                "Konum verisi: Yalnızca konum izni vermeniz halinde yakın kayıtları sıralamak için kullanılır. Koordinatlar, yakındaki kayıtları sorgulamak için hizmet sağlayıcısına iletilebilir.",
                "Teknik veriler: Barındırma ve API sağlayıcıları standart sunucu günlükleri (IP adresi, istek zamanı vb.) üretebilir; bu, güvenlik ve işletim için yaygın bir uygulamadır."
            ]
        ),
        LegalSection(
            heading: "3. Google reklamları ve ölçüm",
            paragraphs: [
                "Uygulamada Google Mobile Ads kullanılabilir. Google, reklamları göstermek ve kişiselleştirmek için tanımlayıcılar ve benzeri teknolojiler kullanabilir. Kişiselleştirilmiş reklamcılık hakkında bilgi için Google Reklam ayarlarını (google.com/settings/ads) ziyaret edebilirsiniz.",
                "Avrupa Ekonomik Alanı veya İngiltere’deyseniz, reklam ortaklarının veri işlemleri için yürürlükteki rıza ve bilgilendirme kurallarına uygun hareket edilmesi gerekir; uygulama içi rıza akışları üretim sürümünde Google UMP ile yönetilir."
            ]
        ),
        LegalSection(
            heading: "4. Harita ve harici içerik",
            paragraphs: [
                "Harita ve yol tarifi Apple Haritalar üzerinden açılır; harita sağlayıcısının kendi gizlilik uygulamaları geçerlidir."
            ]
        ),
        LegalSection(
            heading: "5. KVKK kapsamında haklarınız",
            paragraphs: [
                "6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında; verilerinizin işlenip işlenmediğini öğrenme, düzeltilmesini veya silinmesini isteme, işlenme amacını öğrenme ve mevzuata aykırı işleme halinde şikâyet hakkına sahipsiniz. Cihazınızda tutulan tercih ve önbellek verilerini uygulamayı kaldırarak veya ilgili ayarlardan silebilirsiniz.",
                "Veri sorumlusu bilgileri ve başvuru yolları için uygulama içindeki KVKK aydınlatma metnine bakınız."
            ]
        ),
        LegalSection(
            heading: "6. Politika güncellemeleri",
            paragraphs: [
                "Bu metin zaman zaman güncellenebilir. Önemli değişikliklerde uygulama veya web sitesinde yeni tarih gösterilir."
            ]
        )
    ]

    static let termsSections: [LegalSection] = [
        LegalSection(
            heading: "1. Taraflar ve kabul",
            paragraphs: [
                "Bu kullanım koşulları, Nöbetçim iOS uygulamasını ve nobetcim.info hizmetlerini kullanan herkes için geçerlidir. Uygulamayı kullanmaya devam etmeniz, bu koşulları okuduğunuzu ve kabul ettiğinizi ifade eder."
            ]
        ),
        LegalSection(
            heading: "2. Hizmetin niteliği",
            paragraphs: [
                "Uygulama; yerel hizmet ve işletme bilgilerine erişimi kolaylaştırmak amacıyla “olduğu gibi” sunulur. Hizmet sürekliliği, güncelliği veya belirli bir sonucun elde edilmesi garanti edilmez."
            ]
        ),
        LegalSection(
            heading: "3. Bilgilerin doğruluğu ve sorumluluk reddi",
            paragraphs: [
                "Listeler, mesafeler ve iletişim bilgileri otomatik işleme veya üçüncü taraf kaynaklara dayanabilir. Yanlış, eksik veya güncelliğini yitirmiş veriler oluşabilir. Tıbbi acil durumlarda 112 ve yetkili sağlık kuruluşlarına başvurunuz. İlaç ve tedavi için eczacı veya hekiminize danışınız.",
                "Nöbetçim, bu uygulamadaki bilgilere dayanarak yapılan işlemlerden doğrudan veya dolaylı zararlardan sorumlu tutulamaz."
            ]
        ),
        LegalSection(
            heading: "4. Kullanıcı yükümlülükleri",
            bullets: [
                "Uygulamayı yürürlükteki mevzuata ve üçüncü kişi haklarına aykırı amaçlarla kullanmamayı,",
                "Otomatik tarama, aşırı yük oluşturma veya güvenliği tehdit eden faaliyetlerde bulunmamayı,",
                "Telif hakkı, ticari marka ve kişilik haklarına saygı göstermeyi kabul edersiniz."
            ]
        ),
        LegalSection(
            heading: "5. Fikri mülkiyet",
            paragraphs: [
                "Uygulama tasarımı, metinler ve yazılım bileşenleri ilgili mevzuat kapsamında korunabilir. İzinsiz çoğaltma, dağıtma veya ticari kullanım yasaktır."
            ]
        ),
        LegalSection(
            heading: "6. Üçüncü taraf bağlantıları ve reklamlar",
            paragraphs: [
                "Uygulamada Google reklamları veya diğer üçüncü taraf içerikleri yer alabilir. Bu hizmetlerin koşulları ve gizlilik uygulamaları ilgili sağlayıcılara aittir; ayrıntılar için gizlilik politikamıza bakınız."
            ]
        ),
        LegalSection(
            heading: "7. Değişiklikler ve uygulanacak hukuk",
            paragraphs: [
                "Bu koşullar güncellenebilir; önemli değişikliklerde tarih yenilenir. Uyuşmazlıklarda Türkiye Cumhuriyeti kanunları geçerlidir (tüketici işlemlerinde tüketicinin hakları saklıdır)."
            ]
        )
    ]

    static let kvkkSections: [LegalSection] = [
        LegalSection(
            heading: "Veri sorumlusu",
            paragraphs: [
                "Nöbetçim uygulamasının yürütücüsü, 6698 sayılı Kanun (“KVKK”) uyarınca veri sorumlusu sıfatıyla kişisel verilerinizi aşağıda özetlenen çerçevede işleyebilir. Başvurular için: destek@nobetcim.info"
            ]
        ),
        LegalSection(
            heading: "İşlenen kişisel veriler",
            bullets: [
                "Konum verisi (isteğe bağlı): İzin ile enlem/boylam; yakın kayıt sorgularında kullanılır. İzin verilmezse il ve ilçe seçimi ile arama yapılabilir.",
                "Cihaz verisi: Son arama tercihleri ve günlük önbellek çoğunlukla yalnızca cihazınızda saklanır.",
                "Teknik veri: IP adresi, istek zamanı gibi veriler barındırma ve güvenlik süreçlerinde işlenebilir.",
                "Reklam tanımlayıcıları: Ölçüm ve reklam için üçüncü taraflarca (ör. Google) kullanılabilir."
            ]
        ),
        LegalSection(
            heading: "İşleme amaçları ve hukuki sebepler",
            paragraphs: [
                "Veriler; hizmetin sunulması, kullanıcı deneyiminin iyileştirilmesi, güvenlik, yasal yükümlülüklerin yerine getirilmesi ve — açık rıza veya meşru menfaat çerçevesinde — reklam gösterimi amaçlarıyla işlenebilir. Ayrıntılı açıklama için gizlilik politikamız bu aydınlatma metninin eki sayılır."
            ]
        ),
        LegalSection(
            heading: "Aktarım",
            paragraphs: [
                "Veriler; barındırma, harita ve reklam sağlayıcıları gibi yurt içi veya yurt dışı hizmet sağlayıcılara, hizmetin gerektirdiği ölçüde aktarılabilir."
            ]
        ),
        LegalSection(
            heading: "KVKK madde 11 kapsamındaki haklarınız",
            paragraphs: [
                "Kişisel verilerinizin işlenip işlenmediğini öğrenme, işlenmişse bilgi talep etme, işlenme amacını ve amaca uygun kullanılıp kullanılmadığını öğrenme, yurt içinde veya yurt dışında aktarıldığı üçüncü kişileri bilme, eksik veya yanlış işlenmişse düzeltilmesini isteme, KVKK’da öngörülen şartlar çerçevesinde silinmesini veya yok edilmesini isteme, otomatik sistemlerle aleyhinize sonuç doğmasına itiraz etme ve kanuna aykırı işleme sebebiyle zarar halinde tazminat talep etme haklarına sahipsiniz.",
                "Başvurularınızı veri sorumlusuna yazılı olarak veya Kişisel Verileri Koruma Kurulu’nun öngördüğü diğer yöntemlerle iletebilirsiniz. Şikâyetlerinizi Kurul’a iletme hakkınız saklıdır."
            ]
        )
    ]
}
