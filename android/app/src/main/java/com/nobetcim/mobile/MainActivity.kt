package com.nobetcim.mobile

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas as AndroidCanvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.drawable.BitmapDrawable
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.MotionEvent
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.LocalPharmacy
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.Navigation
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.input.pointer.pointerInteropFilter
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.zIndex
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import java.net.HttpURLConnection
import java.net.URLEncoder
import java.net.URL
import java.net.SocketTimeoutException
import java.net.UnknownHostException
import java.text.Collator
import java.time.DayOfWeek
import java.time.LocalTime
import java.time.ZonedDateTime
import java.time.ZoneId
import java.util.Locale
import kotlin.math.PI
import kotlin.math.atan
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.ln
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sinh
import kotlin.math.tan
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.osmdroid.config.Configuration
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.BoundingBox
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.CustomZoomButtonsController
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            NobetcimTheme {
                NobetcimApp()
            }
        }
    }
}

enum class SearchMode(val title: String) {
    Nearby("Konumuma Göre"),
    City("İl / İlçe")
}

enum class MainTab(val title: String) {
    Pharmacies("Eczaneler"),
    Notaries("Noterler"),
    Map("Harita"),
    More("Daha Fazla")
}

enum class MapFilter(val title: String) {
    All("Hepsi"),
    Pharmacies("Eczaneler"),
    Notaries("Noterler")
}

enum class OperatingStatus(val title: String, val closed: Boolean) {
    Open("Açık", false),
    Duty("Nöbetçi", false),
    Closed("Kapalı", true)
}

object OperatingSchedule {
    private val zone = ZoneId.of("Europe/Istanbul")

    fun pharmacyUsesCatalog(now: ZonedDateTime = ZonedDateTime.now(zone)): Boolean =
        isWeekday(now) && isTime(now, 9, 19)

    fun notaryUsesCatalog(now: ZonedDateTime = ZonedDateTime.now(zone)): Boolean =
        isWeekday(now)

    fun status(isNotary: Boolean, now: ZonedDateTime = ZonedDateTime.now(zone)): OperatingStatus {
        if (!isNotary) {
            return if (pharmacyUsesCatalog(now)) OperatingStatus.Open else OperatingStatus.Duty
        }
        if (isWeekday(now)) {
            return if (isTime(now, 9, 17)) OperatingStatus.Open else OperatingStatus.Closed
        }
        return if (isTime(now, 10, 16)) OperatingStatus.Duty else OperatingStatus.Closed
    }

    fun cacheDateKey(now: ZonedDateTime = ZonedDateTime.now(zone)): String =
        now.toLocalDate().toString()

    private fun isWeekday(now: ZonedDateTime): Boolean =
        now.dayOfWeek != DayOfWeek.SATURDAY && now.dayOfWeek != DayOfWeek.SUNDAY

    private fun isTime(now: ZonedDateTime, startHour: Int, endHour: Int): Boolean {
        val current = now.toLocalTime()
        return !current.isBefore(LocalTime.of(startHour, 0)) && current.isBefore(LocalTime.of(endHour, 0))
    }
}

data class PlaceSelection(
    val place: Pharmacy,
    val isNotary: Boolean
)

data class MapPlace(
    val place: Pharmacy,
    val isNotary: Boolean
)

data class MapTile(
    val x: Int,
    val y: Int,
    val zoom: Int,
    val left: Double,
    val top: Double
) {
    val url: String = "https://tile.openstreetmap.org/$zoom/$x/$y.png"
}

data class Pharmacy(
    val id: String,
    val name: String,
    val city: String,
    val district: String,
    val address: String,
    val phone: String?,
    val latitude: Double?,
    val longitude: Double?,
    val distanceKm: Double?
)

data class CityInfo(
    val name: String,
    val slug: String
)

data class DistrictInfo(
    val name: String,
    val slug: String
)

data class UiState(
    val selectedTab: MainTab = MainTab.Pharmacies,
    val mode: SearchMode = SearchMode.Nearby,
    val city: String = "İstanbul",
    val district: String = "Kadıköy",
    val cities: List<CityInfo> = emptyList(),
    val districts: List<DistrictInfo> = emptyList(),
    val pharmacies: List<Pharmacy> = emptyList(),
    val notaries: List<Pharmacy> = emptyList(),
    val isLoading: Boolean = false,
    val isDirectoryLoading: Boolean = false,
    val hasSearched: Boolean = false,
    val errorMessage: String? = null
)

class PharmacyViewModel : ViewModel() {
    private val repository = NobetcimRepository(NobetcimApiClient())
    private val _state = MutableStateFlow(UiState())
    val state: StateFlow<UiState> = _state

    private val UiState.activePlaces: List<Pharmacy>
        get() = if (selectedTab == MainTab.Notaries) notaries else pharmacies

    fun loadDirectory() {
        if (_state.value.cities.isNotEmpty() || _state.value.isDirectoryLoading) return
        viewModelScope.launch {
            _state.update { it.copy(isDirectoryLoading = true) }
            val cities = repository.loadCities().ifEmpty { fallbackCities }
            val city = cities.firstOrNull { it.name.matchesTurkish(_state.value.city) }?.name
                ?: cities.firstOrNull()?.name
                ?: _state.value.city
            _state.update { it.copy(cities = cities, city = city, isDirectoryLoading = false) }
            loadDistricts(city, _state.value.selectedTab)
        }
    }

    fun setTab(tab: MainTab) {
        _state.update { it.copy(selectedTab = tab, errorMessage = null) }
        if (tab == MainTab.Pharmacies || tab == MainTab.Notaries) {
            loadDistricts(_state.value.city, tab)
        }
    }

    fun setMode(mode: SearchMode) {
        _state.update {
            it.copy(mode = mode, hasSearched = false, errorMessage = null)
        }
    }

    fun setCity(city: String) {
        _state.update { it.copy(city = city, district = "") }
        loadDistricts(city, _state.value.selectedTab)
    }

    fun setDistrict(district: String) {
        _state.update { it.copy(district = district) }
    }

    fun searchNearby(location: Location?) {
        val current = _state.value
        if (location == null) {
            _state.update {
                it.copy(
                    hasSearched = true,
                    errorMessage = "Konum alınamadı. İzinleri kontrol edip tekrar deneyin."
                )
            }
            return
        }

        viewModelScope.launch {
            val isNotary = _state.value.selectedTab == MainTab.Notaries
            val snapshot = _state.value
            runSearch(isNotary = isNotary) {
                val results = if (isNotary) repository.fetchNearbyNotaries(
                    latitude = location.latitude,
                    longitude = location.longitude,
                    radius = 50000,
                    citySlug = snapshot.cities.firstOrNull { it.name.matchesTurkish(snapshot.city) }?.slug
                        ?: snapshot.city.slugifiedTurkish()
                ) else repository.fetchNearbyPharmaciesForSchedule(
                    latitude = location.latitude,
                    longitude = location.longitude,
                    radius = 50000,
                    citySlug = snapshot.cities.firstOrNull { it.name.matchesTurkish(snapshot.city) }?.slug
                        ?: snapshot.city.slugifiedTurkish(),
                    districtSlug = snapshot.district.takeIf { it.isNotBlank() }?.slugifiedTurkish()
                )
                results.sortedByDistance(location)
            }
        }
    }

    fun searchByCity() {
        viewModelScope.launch {
            val snapshot = _state.value
            val isNotary = snapshot.selectedTab == MainTab.Notaries
            runSearch(isNotary = isNotary) {
                val citySlug = snapshot.cities.firstOrNull { it.name.matchesTurkish(snapshot.city) }?.slug
                    ?: snapshot.city.slugifiedTurkish()
                val districtSlug = snapshot.district.takeIf { it.isNotBlank() }?.slugifiedTurkish()
                if (isNotary) {
                    repository.fetchNotariesForSchedule(citySlug, districtSlug)
                } else {
                    repository.fetchPharmaciesForSchedule(citySlug, districtSlug)
                }
            }
        }
    }

    fun loadMapNearby(location: Location?) {
        if (location == null) {
            _state.update {
                it.copy(
                    hasSearched = true,
                    errorMessage = "Konum alınamadı. İzinleri kontrol edip tekrar deneyin."
                )
            }
            return
        }

        viewModelScope.launch {
            val snapshot = _state.value
            if (snapshot.pharmacies.isNotEmpty() && snapshot.notaries.isNotEmpty()) return@launch
            _state.update { it.copy(isLoading = true, errorMessage = null) }

            val citySlug = snapshot.cities.firstOrNull { it.name.matchesTurkish(snapshot.city) }?.slug
                ?: snapshot.city.slugifiedTurkish()
            val pharmacyResult = if (snapshot.pharmacies.isEmpty()) {
                runCatching {
                    repository.fetchNearbyPharmaciesForSchedule(
                        latitude = location.latitude,
                        longitude = location.longitude,
                        radius = 50000,
                        citySlug = citySlug,
                        districtSlug = snapshot.district.takeIf { it.isNotBlank() }?.slugifiedTurkish()
                    ).sortedByDistance(location)
                }
            } else {
                Result.success(snapshot.pharmacies)
            }
            val notaryResult = if (snapshot.notaries.isEmpty()) {
                runCatching {
                    repository.fetchNearbyNotaries(
                        latitude = location.latitude,
                        longitude = location.longitude,
                        radius = 50000,
                        citySlug = citySlug
                    ).sortedByDistance(location)
                }
            } else {
                Result.success(snapshot.notaries)
            }

            _state.update { state ->
                state.copy(
                    pharmacies = pharmacyResult.getOrElse { state.pharmacies },
                    notaries = notaryResult.getOrElse { state.notaries },
                    isLoading = false,
                    hasSearched = true,
                    errorMessage = pharmacyResult.exceptionOrNull()?.toUserMessage("Eczane bilgileri alınamadı.")
                        ?: notaryResult.exceptionOrNull()?.toUserMessage("Noter bilgileri alınamadı.")
                )
            }
        }
    }

    private fun loadDistricts(city: String, tab: MainTab) {
        viewModelScope.launch {
            val citySlug = _state.value.cities.firstOrNull { it.name.matchesTurkish(city) }?.slug
                ?: city.slugifiedTurkish()
            val districts = repository.loadDistricts(citySlug, notary = tab == MainTab.Notaries).ifEmpty {
                fallbackDistricts[city.slugifiedTurkish()].orEmpty()
            }
            _state.update { state ->
                val selected = state.district.takeIf { value ->
                    value.isNotBlank() && districts.any { it.name.matchesTurkish(value) }
                }.orEmpty()
                state.copy(districts = districts, district = selected)
            }
        }
    }

    private suspend fun runSearch(isNotary: Boolean, fetch: suspend () -> List<Pharmacy>) {
        _state.update {
            if (isNotary) {
                it.copy(isLoading = true, notaries = emptyList(), errorMessage = null)
            } else {
                it.copy(isLoading = true, pharmacies = emptyList(), errorMessage = null)
            }
        }
        val result = runCatching { fetch() }
        _state.update { state ->
            result.fold(
                onSuccess = { places ->
                    state.copy(
                        pharmacies = if (isNotary) state.pharmacies else places,
                        notaries = if (isNotary) places else state.notaries,
                        isLoading = false,
                        hasSearched = true,
                        errorMessage = if (places.isEmpty()) {
                            if (isNotary) "Bu bölgede noter bulunamadı." else "Bu bölgede eczane bulunamadı."
                        } else null
                    )
                },
                onFailure = { error ->
                    state.copy(
                        isLoading = false,
                        hasSearched = true,
                        errorMessage = error.toUserMessage(
                            fallback = if (isNotary) "Noter bilgileri alınamadı." else "Eczane bilgileri alınamadı."
                        )
                    )
                }
            )
        }
    }
}

private class NobetcimRepository(
    private val api: NobetcimApiClient
) {
    private val memoryCache = mutableMapOf<String, List<Pharmacy>>()
    private var citiesCache: List<CityInfo>? = null
    private val districtCache = mutableMapOf<String, List<DistrictInfo>>()

    private suspend fun cached(key: String, fetch: suspend () -> List<Pharmacy>): List<Pharmacy> {
        val scopedKey = "${OperatingSchedule.cacheDateKey()}|$key"
        memoryCache[scopedKey]?.let { return it }
        return fetch().also { memoryCache[scopedKey] = it }
    }

    suspend fun fetchDutyPharmacies(citySlug: String, districtSlug: String?): List<Pharmacy> =
        cached("duty-pharmacy|$citySlug|${districtSlug.orEmpty()}") {
            api.getArray(
                path = "nobetci",
                params = mapOf("il" to citySlug, "ilce" to districtSlug)
            ).mapPharmacies()
        }

    suspend fun fetchCatalogPharmacies(citySlug: String?, districtSlug: String?, page: Int = 1, limit: Int = 100): List<Pharmacy> =
        cached("catalog-pharmacy|${citySlug.orEmpty()}|${districtSlug.orEmpty()}|$page|$limit") {
            api.getArray(
                path = "eczaneler",
                params = mapOf("il" to citySlug, "ilce" to districtSlug, "page" to page.toString(), "limit" to limit.toString())
            ).mapPharmacies()
        }

    suspend fun fetchNearby(latitude: Double, longitude: Double, radius: Int): List<Pharmacy> =
        cached("nearby-pharmacy|${latitude.cacheCoordinate()}|${longitude.cacheCoordinate()}|$radius") {
            api.getArray(
                path = "konum",
                params = mapOf("lat" to latitude.toString(), "lng" to longitude.toString(), "radius" to radius.toString())
            ).mapPharmacies()
        }

    suspend fun fetchNearbyCatalogPharmacies(latitude: Double, longitude: Double, radius: Int, limit: Int = 50): List<Pharmacy> =
        cached("nearby-catalog-pharmacy|${latitude.cacheCoordinate()}|${longitude.cacheCoordinate()}|$radius|$limit") {
            api.getArray(
                path = "eczaneler",
                params = mapOf(
                    "lat" to latitude.toString(),
                    "lng" to longitude.toString(),
                    "radius" to radius.toString(),
                    "limit" to limit.toString()
                )
            ).mapPharmacies()
        }

    suspend fun fetchPharmaciesForSchedule(citySlug: String, districtSlug: String?): List<Pharmacy> =
        if (OperatingSchedule.pharmacyUsesCatalog()) {
            fetchCatalogPharmacies(citySlug, districtSlug)
        } else {
            fetchDutyPharmacies(citySlug, districtSlug)
        }

    suspend fun fetchNearbyPharmaciesForSchedule(
        latitude: Double,
        longitude: Double,
        radius: Int,
        citySlug: String?,
        districtSlug: String?
    ): List<Pharmacy> =
        if (OperatingSchedule.pharmacyUsesCatalog()) {
            fetchNearbyCatalogPharmacies(latitude, longitude, radius)
                .ifEmpty { fetchCatalogPharmacies(citySlug, districtSlug, limit = 100) }
        } else {
            fetchNearby(latitude, longitude, radius)
        }

    suspend fun fetchDutyNotaries(citySlug: String, districtSlug: String?): List<Pharmacy> =
        cached("duty-notary|$citySlug|${districtSlug.orEmpty()}") {
            api.getArray(
                path = "nobetci-noter",
                params = mapOf("il" to citySlug, "ilce" to districtSlug)
            ).mapNotaries()
        }

    suspend fun fetchCatalogNotaries(citySlug: String?, districtSlug: String?, page: Int = 1, limit: Int = 100): List<Pharmacy> =
        cached("catalog-notary|${citySlug.orEmpty()}|${districtSlug.orEmpty()}|$page|$limit") {
            api.getArray(
                path = "noterler",
                params = mapOf("il" to citySlug, "ilce" to districtSlug, "page" to page.toString(), "limit" to limit.toString())
            ).mapNotaries()
        }

    suspend fun fetchNearbyNotaries(latitude: Double, longitude: Double, radius: Int, citySlug: String?): List<Pharmacy> =
        if (OperatingSchedule.notaryUsesCatalog()) {
            fetchCatalogNotaries(citySlug = citySlug, districtSlug = null).sortedByDistance(latitude, longitude)
        } else {
            cached("nearby-duty-notary|${latitude.cacheCoordinate()}|${longitude.cacheCoordinate()}|$radius") {
                api.getArray(
                    path = "noter-konum",
                    params = mapOf("lat" to latitude.toString(), "lng" to longitude.toString(), "radius" to radius.toString())
                ).mapNotaries()
            }
        }

    suspend fun fetchNotariesForSchedule(citySlug: String, districtSlug: String?): List<Pharmacy> =
        if (OperatingSchedule.notaryUsesCatalog()) {
            fetchCatalogNotaries(citySlug, districtSlug)
        } else {
            fetchDutyNotaries(citySlug, districtSlug)
        }

    suspend fun loadCities(): List<CityInfo> =
        citiesCache ?: runCatching {
            api.getArray("iller").mapObjects { item ->
                CityInfo(
                    name = item.optString("ad").titleCaseTurkish(),
                    slug = item.optString("slug").ifBlank { item.optString("ad").slugifiedTurkish() }
                )
            }.sortedWith(turkishComparator<CityInfo> { it.name }).also { citiesCache = it }
        }.getOrElse { emptyList() }

    suspend fun loadDistricts(citySlug: String, notary: Boolean = false): List<DistrictInfo> {
        val key = "$citySlug|$notary"
        districtCache[key]?.let { return it }
        return runCatching {
            api.getArray("ilceler", mapOf("il" to citySlug, "tur" to if (notary) "noter" else null)).mapObjects { item ->
                DistrictInfo(
                    name = item.optString("ad").titleCaseTurkish(),
                    slug = item.optString("slug").ifBlank { item.optString("ad").slugifiedTurkish() }
                )
            }.sortedWith(turkishComparator<DistrictInfo> { it.name }).also { districtCache[key] = it }
        }.getOrElse { emptyList() }
    }
}

private class NobetcimApiClient(
    private val baseUrl: String = BuildConfig.NOBETCIM_BASE_URL,
    private val apiKey: String = BuildConfig.NOBETCIM_API_KEY
) {
    suspend fun getArray(path: String, params: Map<String, String?> = emptyMap()): JSONArray {
        val body = request(path, params)
        val data = body.opt("data")
        return when (data) {
            is JSONArray -> data
            null -> JSONArray()
            else -> throw IllegalStateException("Sunucu yanıtı beklenen liste formatında değil.")
        }
    }

    private suspend fun request(path: String, params: Map<String, String?>): JSONObject = withContext(Dispatchers.IO) {
        require(apiKey.isNotBlank()) { "API anahtarı yapılandırılmamış." }
        val query = params
            .filterValues { !it.isNullOrBlank() }
            .entries
            .joinToString("&") { (key, value) -> "${key.encodeUrl()}=${value.orEmpty().encodeUrl()}" }
        val url = URL(baseUrl.trimEnd('/') + "/" + path.trimStart('/') + if (query.isBlank()) "" else "?$query")
        val connection = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 20_000
            readTimeout = 20_000
            setRequestProperty("Accept", "application/json")
            setRequestProperty("Cache-Control", "no-cache")
            setRequestProperty("X-API-Key", apiKey)
        }

        val status = connection.responseCode
        val stream = if (status in 200..299) connection.inputStream else connection.errorStream
        val text = stream?.bufferedReader()?.use { it.readText() }.orEmpty()
        val json = JSONObject(text.ifBlank { "{}" })
        if (status !in 200..299 || json.optBoolean("success", true).not()) {
            throw IllegalStateException(json.optString("error").ifBlank { status.toUserMessage() })
        }
        json
    }
}

@Composable
private fun NobetcimApp(viewModel: PharmacyViewModel = viewModel()) {
    val state by viewModel.state.collectAsState()
    val context = LocalContext.current
    val errorMessage = state.errorMessage
    var location by remember { mutableStateOf<Location?>(null) }
    var selectedPlace by remember { mutableStateOf<PlaceSelection?>(null) }
    var isFilterExpanded by remember { mutableStateOf(true) }
    var autoSearchRequestedTabs by remember { mutableStateOf(emptySet<MainTab>()) }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { result ->
        if (result.values.any { it }) {
            location = context.bestKnownLocation()
            if (state.selectedTab == MainTab.Map) {
                viewModel.loadMapNearby(location)
                context.requestFreshLocation { freshLocation ->
                    location = freshLocation
                    viewModel.loadMapNearby(freshLocation)
                }
            } else {
                viewModel.searchNearby(location)
            }
        }
    }

    LaunchedEffect(Unit) {
        viewModel.loadDirectory()
    }

    LaunchedEffect(state.selectedTab) {
        selectedPlace = null
        isFilterExpanded = state.selectedTab == MainTab.Pharmacies || state.selectedTab == MainTab.Notaries
        if (state.selectedTab == MainTab.Map) {
            if (locationPermissionsGranted(context)) {
                location = context.bestKnownLocation()
                viewModel.loadMapNearby(location)
                context.requestFreshLocation { freshLocation ->
                    location = freshLocation
                    viewModel.loadMapNearby(freshLocation)
                }
            } else {
                permissionLauncher.launch(
                    arrayOf(
                        Manifest.permission.ACCESS_FINE_LOCATION,
                        Manifest.permission.ACCESS_COARSE_LOCATION
                    )
                )
            }
        }
    }

    LaunchedEffect(state.selectedTab, state.mode, state.pharmacies.size, state.notaries.size, state.isLoading) {
        val activePlaces = if (state.selectedTab == MainTab.Notaries) state.notaries else state.pharmacies
        val canAutoSearch = state.selectedTab == MainTab.Pharmacies || state.selectedTab == MainTab.Notaries
        if (
            canAutoSearch &&
            state.mode == SearchMode.Nearby &&
            activePlaces.isEmpty() &&
            !state.isLoading &&
            state.selectedTab !in autoSearchRequestedTabs
        ) {
            autoSearchRequestedTabs = autoSearchRequestedTabs + state.selectedTab
            if (locationPermissionsGranted(context)) {
                location = context.bestKnownLocation()
                viewModel.searchNearby(location)
            } else {
                permissionLauncher.launch(
                    arrayOf(
                        Manifest.permission.ACCESS_FINE_LOCATION,
                        Manifest.permission.ACCESS_COARSE_LOCATION
                    )
                )
            }
        }
    }

    Scaffold(
        bottomBar = {
            BottomTabBar(
                selected = state.selectedTab,
                onSelected = viewModel::setTab
            )
        },
        containerColor = AppColors.Background
    ) { padding ->
        val activePlaces = if (state.selectedTab == MainTab.Notaries) state.notaries else state.pharmacies
        val isNotary = state.selectedTab == MainTab.Notaries
        val detail = selectedPlace
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 18.dp),
            userScrollEnabled = state.selectedTab != MainTab.Map || detail != null,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            if (detail == null && state.selectedTab != MainTab.Map) {
                item {
                    Text(
                        text = "Nöbetçim Cebinde",
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 0.dp, bottom = 8.dp),
                        fontSize = 22.sp,
                        lineHeight = 26.sp,
                        fontWeight = FontWeight.ExtraBold,
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                        color = AppColors.Text
                    )
                }
            }

            if (detail != null) {
                item {
                    DetailScreen(
                        selection = detail,
                        currentLocation = location,
                        context = context,
                        onBack = { selectedPlace = null }
                    )
                }
            } else if (state.selectedTab == MainTab.Pharmacies || state.selectedTab == MainTab.Notaries) {
                item {
                    SearchPanel(
                        state = state,
                        isNotary = isNotary,
                        expanded = isFilterExpanded,
                        onToggleExpanded = { isFilterExpanded = !isFilterExpanded },
                        onModeChange = viewModel::setMode,
                        onCityChange = viewModel::setCity,
                        onDistrictChange = viewModel::setDistrict,
                        onSearch = {
                            isFilterExpanded = false
                            if (state.mode == SearchMode.Nearby) {
                                val granted = locationPermissionsGranted(context)
                                if (granted) {
                                    location = context.bestKnownLocation()
                                    viewModel.searchNearby(location)
                                } else {
                                    permissionLauncher.launch(
                                        arrayOf(
                                            Manifest.permission.ACCESS_FINE_LOCATION,
                                            Manifest.permission.ACCESS_COARSE_LOCATION
                                        )
                                    )
                                }
                            } else {
                                viewModel.searchByCity()
                            }
                        }
                    )
                }
            }

            if (detail != null) {
                // Detail content is rendered above.
            } else if (state.selectedTab == MainTab.Map) {
                item {
                    MapScreen(
                        places = buildList {
                            addAll(state.pharmacies.map { MapPlace(it, isNotary = false) })
                            addAll(state.notaries.map { MapPlace(it, isNotary = true) })
                        }.distinctBy { "${it.isNotary}-${it.place.id}" },
                        currentLocation = location,
                        onPlaceSelected = { selectedPlace = PlaceSelection(it.place, it.isNotary) }
                    )
                }
            } else if (state.selectedTab == MainTab.More) {
                item {
                    MoreScreen(
                        onOpenPharmacies = { viewModel.setTab(MainTab.Pharmacies) },
                        onOpenNotaries = { viewModel.setTab(MainTab.Notaries) },
                        onOpenMap = { viewModel.setTab(MainTab.Map) }
                    )
                }
            } else {
                when {
                    state.isLoading -> item { LoadingState(isNotary = isNotary) }
                    errorMessage != null && activePlaces.isEmpty() -> item {
                        MessageState(
                            title = "Sonuç alınamadı",
                            message = errorMessage,
                            color = if (isNotary) AppColors.Notary else AppColors.Primary,
                            softColor = if (isNotary) AppColors.NotarySoft else AppColors.PrimarySoft,
                            icon = { Icon(Icons.Default.ErrorOutline, null) }
                        )
                    }
                    activePlaces.isEmpty() && state.hasSearched -> item {
                        MessageState(
                            title = "Sonuç bulunamadı",
                            message = "Farklı bir il veya ilçe seçerek tekrar deneyin.",
                            color = if (isNotary) AppColors.Notary else AppColors.Primary,
                            softColor = if (isNotary) AppColors.NotarySoft else AppColors.PrimarySoft,
                            icon = { Icon(if (isNotary) Icons.Default.Description else Icons.Default.LocalPharmacy, null) }
                        )
                    }
                    activePlaces.isEmpty() -> item {
                        MessageState(
                            title = "Arama yapın",
                            message = if (isNotary) {
                                "Konumunuza göre veya il / ilçe seçerek noterleri listeleyin."
                            } else {
                                "Konumunuza göre veya il / ilçe seçerek eczaneleri listeleyin."
                            },
                            color = if (isNotary) AppColors.Notary else AppColors.Primary,
                            softColor = if (isNotary) AppColors.NotarySoft else AppColors.PrimarySoft,
                            icon = { Icon(if (isNotary) Icons.Default.Description else Icons.Default.Search, null) }
                        )
                    }
                    else -> items(activePlaces, key = { it.id }) { place ->
                        PharmacyCard(
                            pharmacy = place,
                            context = context,
                            isNotary = isNotary,
                            onOpenDetail = { selectedPlace = PlaceSelection(place, isNotary) }
                        )
                    }
                }
            }

            item { Spacer(Modifier.height(18.dp)) }
        }
    }
}

@Composable
private fun SearchPanel(
    state: UiState,
    isNotary: Boolean,
    expanded: Boolean,
    onToggleExpanded: () -> Unit,
    onModeChange: (SearchMode) -> Unit,
    onCityChange: (String) -> Unit,
    onDistrictChange: (String) -> Unit,
    onSearch: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, AppColors.Border, RoundedCornerShape(AppMetrics.CardRadius)),
        shape = RoundedCornerShape(AppMetrics.CardRadius),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        val accent = if (isNotary) AppColors.Notary else AppColors.Primary
        val accentSoft = if (isNotary) AppColors.NotarySoft else AppColors.PrimarySoft
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onToggleExpanded),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(accentSoft),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(Icons.Default.Tune, contentDescription = null, tint = accent, modifier = Modifier.size(25.dp))
                }
                Spacer(Modifier.width(14.dp))
                Column(Modifier.weight(1f)) {
                    Text(
                        "Arama filtresi",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.ExtraBold,
                        color = AppColors.Text
                    )
                    Text(
                        if (state.mode == SearchMode.Nearby) "Konumuma göre" else listOf(state.city, state.district).filter { it.isNotBlank() }.joinToString(" / "),
                        style = MaterialTheme.typography.bodyLarge,
                        color = AppColors.Muted,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                Icon(
                    if (expanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                    contentDescription = null,
                    tint = AppColors.SecondaryText,
                    modifier = Modifier.size(30.dp)
                )
            }

            if (expanded) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(28.dp))
                        .background(AppColors.SegmentedBackground)
                        .padding(3.dp),
                    horizontalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    SearchMode.entries.forEach { mode ->
                        SegmentButton(
                            modifier = Modifier.weight(1f),
                            text = mode.title,
                            selected = state.mode == mode,
                            onClick = { onModeChange(mode) }
                        )
                    }
                }

                if (state.mode == SearchMode.City) {
                    PickerField(
                        label = "İl",
                        value = state.city,
                        options = state.cities.map { it.name },
                        isLoading = state.isDirectoryLoading,
                        onSelect = onCityChange
                    )
                    PickerField(
                        label = "İlçe",
                        value = state.district.ifBlank { "Tüm ilçeler" },
                        options = state.districts.map { it.name },
                        includesAllOption = true,
                        isLoading = state.isDirectoryLoading && state.districts.isEmpty(),
                        onSelect = onDistrictChange
                    )
                }

                TextButton(
                    onClick = onSearch,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(58.dp)
                        .clip(RoundedCornerShape(30.dp)),
                    enabled = !state.isLoading,
                    colors = ButtonDefaults.textButtonColors(
                        containerColor = accent,
                        contentColor = Color.White,
                        disabledContainerColor = accent.copy(alpha = 0.45f),
                        disabledContentColor = Color.White.copy(alpha = 0.85f)
                    )
                ) {
                    Icon(Icons.Default.Search, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(10.dp))
                    Text(
                        when {
                            isNotary && state.mode == SearchMode.Nearby -> "Yakındaki Noterleri Ara"
                            isNotary -> "Noter Ara"
                            state.mode == SearchMode.Nearby -> "Yakındaki Eczaneleri Ara"
                            else -> "Eczane Ara"
                        },
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp
                    )
                }
            }
        }
    }
}

@Composable
private fun SegmentButton(modifier: Modifier = Modifier, text: String, selected: Boolean, onClick: () -> Unit) {
    Box(
        modifier = modifier
            .height(44.dp)
            .clip(RoundedCornerShape(23.dp))
            .background(if (selected) Color.White else Color.Transparent)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(text, fontWeight = FontWeight.Bold, color = AppColors.Text, fontSize = 15.sp, maxLines = 1)
    }
}

@Composable
private fun PickerField(
    label: String,
    value: String,
    options: List<String>,
    includesAllOption: Boolean = false,
    isLoading: Boolean = false,
    onSelect: (String) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    val menuOptions = if (includesAllOption) listOf("Tüm ilçeler") + options else options
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(label, color = AppColors.Muted, fontSize = 13.sp)
        Box {
            Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp)
                .border(1.dp, AppColors.Border, RoundedCornerShape(12.dp))
                    .clickable(enabled = !isLoading && menuOptions.isNotEmpty()) { expanded = true }
                .padding(horizontal = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
                Text(value, modifier = Modifier.weight(1f), color = AppColors.Text, fontSize = 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            if (isLoading) {
                CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp, color = AppColors.Primary)
                } else {
                    Icon(Icons.Default.KeyboardArrowDown, contentDescription = null, tint = AppColors.SecondaryText)
                }
            }
            DropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false },
                modifier = Modifier
                    .fillMaxWidth(0.86f)
                    .heightIn(max = 320.dp)
            ) {
                menuOptions.forEach { option ->
                    DropdownMenuItem(
                        text = { Text(option) },
                        onClick = {
                            expanded = false
                            onSelect(if (includesAllOption && option == "Tüm ilçeler") "" else option)
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun DistrictPill(text: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .height(36.dp)
            .border(1.dp, AppColors.Border, RoundedCornerShape(18.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(text, color = AppColors.Text, fontSize = 13.sp, fontWeight = FontWeight.Medium)
    }
}

@Composable
private fun PharmacyCard(
    pharmacy: Pharmacy,
    context: Context,
    isNotary: Boolean = false,
    onOpenDetail: () -> Unit = {}
) {
    val accent = if (isNotary) AppColors.Notary else AppColors.Primary
    val accentSoft = if (isNotary) AppColors.NotarySoft else AppColors.PrimarySoft
    val status = OperatingSchedule.status(isNotary)
    val statusColor = if (status.closed) AppColors.Muted else accent
    val statusSoft = if (status.closed) AppColors.Background else accentSoft
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onOpenDetail)
            .border(1.dp, AppColors.Border, RoundedCornerShape(AppMetrics.CardRadius)),
        shape = RoundedCornerShape(AppMetrics.CardRadius),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(verticalAlignment = Alignment.Top) {
                Box(
                    Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(accentSoft),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        if (isNotary) Icons.Default.Description else Icons.Default.LocalPharmacy,
                        contentDescription = null,
                        tint = accent,
                        modifier = Modifier.size(27.dp)
                    )
                }
                Spacer(Modifier.width(14.dp))
                Column(Modifier.weight(1f)) {
                    Text(
                        pharmacy.name,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.ExtraBold,
                        color = AppColors.Text,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        listOf(pharmacy.district, pharmacy.city).filter { it.isNotBlank() }.joinToString(" / "),
                        style = MaterialTheme.typography.titleMedium,
                        color = AppColors.Muted,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            Text(
                pharmacy.address,
                style = MaterialTheme.typography.titleMedium,
                color = AppColors.Muted,
                lineHeight = 22.sp,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis
            )

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Badge(
                    text = status.title,
                    color = statusColor,
                    softColor = statusSoft,
                    icon = { Icon(if (status.closed) Icons.Default.ErrorOutline else Icons.Default.CheckCircle, null, modifier = Modifier.size(16.dp)) }
                )
                pharmacy.distanceKm?.let {
                    Badge(text = String.format(Locale("tr", "TR"), "%.1f km", it), color = accent, softColor = accentSoft, icon = { Icon(Icons.Default.Navigation, null, modifier = Modifier.size(16.dp)) })
                }
            }

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                ActionButton(
                    modifier = Modifier.weight(1f),
                    text = "Ara",
                    icon = { Icon(Icons.Default.Call, null, modifier = Modifier.size(20.dp)) },
                    filled = true,
                    color = accent,
                    softColor = accentSoft
                ) { context.callPhone(pharmacy.phone) }
                ActionButton(
                    modifier = Modifier.weight(1f),
                    text = "Yol Tarifi",
                    icon = { Icon(Icons.Default.Navigation, null, modifier = Modifier.size(20.dp)) },
                    filled = false,
                    color = accent,
                    softColor = accentSoft
                ) { context.openDirections(pharmacy) }
            }
        }
    }
}

@Composable
private fun DetailScreen(selection: PlaceSelection, currentLocation: Location?, context: Context, onBack: () -> Unit) {
    val place = selection.place
    val accent = if (selection.isNotary) AppColors.Notary else AppColors.Primary
    val accentSoft = if (selection.isNotary) AppColors.NotarySoft else AppColors.PrimarySoft
    val status = OperatingSchedule.status(selection.isNotary)
    val statusColor = if (status.closed) AppColors.Muted else accent
    val statusSoft = if (status.closed) AppColors.Background else accentSoft

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Box(Modifier.fillMaxWidth()) {
            Surface(
                modifier = Modifier
                    .align(Alignment.CenterStart)
                    .size(56.dp),
                color = Color.White,
                shape = CircleShape,
                shadowElevation = 0.dp,
                contentColor = accent
            ) {
                Box(Modifier.clickable(onClick = onBack), contentAlignment = Alignment.Center) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null, modifier = Modifier.size(30.dp))
                }
            }
            Text(
                if (selection.isNotary) "Noter Detayı" else "Eczane Detayı",
                modifier = Modifier.align(Alignment.Center),
                fontWeight = FontWeight.ExtraBold,
                fontSize = 20.sp,
                color = AppColors.Text
            )
        }

        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = accentSoft,
            shape = RoundedCornerShape(0.dp),
            contentColor = accent
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 20.dp),
                verticalAlignment = Alignment.Top
            ) {
                Surface(color = Color.White.copy(alpha = 0.92f), shape = CircleShape, contentColor = accent) {
                    Box(Modifier.size(50.dp), contentAlignment = Alignment.Center) {
                        Icon(
                            if (selection.isNotary) Icons.Default.Description else Icons.Default.LocalPharmacy,
                            contentDescription = null,
                            modifier = Modifier.size(28.dp)
                        )
                    }
                }
                Spacer(Modifier.width(14.dp))
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(place.name, fontWeight = FontWeight.ExtraBold, fontSize = 23.sp, lineHeight = 27.sp, color = AppColors.Text)
                    Text(listOf(place.district, place.city).filter { it.isNotBlank() }.joinToString(" / "), color = AppColors.Muted, fontSize = 16.sp)
                    Badge(
                        text = status.title,
                        color = statusColor,
                        softColor = if (status.closed) Color.White.copy(alpha = 0.75f) else Color.White.copy(alpha = 0.70f),
                        icon = { Icon(if (status.closed) Icons.Default.ErrorOutline else Icons.Default.CheckCircle, null, modifier = Modifier.size(15.dp)) }
                    )
                }
            }
        }

        if (place.latitude != null && place.longitude != null) {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, AppColors.Border, RoundedCornerShape(AppMetrics.CardRadius)),
                shape = RoundedCornerShape(AppMetrics.CardRadius),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(0.dp)) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(220.dp)
                    ) {
                        var detailMapView by remember { mutableStateOf<MapView?>(null) }
                        OsmMap(
                            places = listOf(MapPlace(place, selection.isNotary)),
                            currentLocation = currentLocation,
                            onMapReady = { detailMapView = it },
                            onMarkerSelected = {}
                        )
                        MapZoomControls(
                            mapView = detailMapView,
                            modifier = Modifier
                                .align(Alignment.TopEnd)
                                .padding(top = 10.dp, end = 10.dp)
                        )
                    }
                    ActionButton(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        text = "Yol Tarifi",
                        icon = { Icon(Icons.Default.Navigation, null, modifier = Modifier.size(20.dp)) },
                        filled = true,
                        color = accent,
                        softColor = accentSoft
                    ) { context.openDirections(place) }
                }
            }
        }

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, AppColors.Border, RoundedCornerShape(AppMetrics.CardRadius)),
            shape = RoundedCornerShape(AppMetrics.CardRadius),
            colors = CardDefaults.cardColors(containerColor = Color.White),
            elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
        ) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                InfoLine("Adres", place.address, Icons.Default.LocationOn, accent)
                InfoLine("Telefon", place.phone ?: "Telefon numarası bulunamadı.", Icons.Default.Call, accent)
                InfoLine("Konum", listOf(place.district, place.city).filter { it.isNotBlank() }.joinToString(" / "), Icons.Default.Map, accent)
                place.distanceKm?.let {
                    InfoLine("Mesafe", String.format(Locale("tr", "TR"), "%.1f km", it), Icons.Default.MyLocation, accent)
                }
            }
        }

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, AppColors.Border, RoundedCornerShape(AppMetrics.CardRadius)),
            shape = RoundedCornerShape(AppMetrics.CardRadius),
            colors = CardDefaults.cardColors(containerColor = Color.White),
            elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
        ) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                ActionButton(
                    modifier = Modifier.fillMaxWidth(),
                    text = if (selection.isNotary) "Noteri Ara" else "Eczaneyi Ara",
                    icon = { Icon(Icons.Default.Call, null, modifier = Modifier.size(20.dp)) },
                    filled = true,
                    color = accent,
                    softColor = accentSoft
                ) { context.callPhone(place.phone) }
                ActionButton(
                    modifier = Modifier.fillMaxWidth(),
                    text = "Google Haritalar ile Aç",
                    icon = { Icon(Icons.Default.Map, null, modifier = Modifier.size(20.dp)) },
                    filled = false,
                    color = accent,
                    softColor = accentSoft
                ) { context.openDirections(place) }
            }
        }

        Text(
            "Bilgiler kaynak verilerden alınır. Gitmeden önce işletme ile iletişime geçmeniz önerilir.",
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(Color(0xFFFFF4D7))
                .padding(16.dp),
            color = AppColors.Muted,
            fontSize = 13.sp,
            lineHeight = 18.sp
        )
    }
}

@Composable
private fun InfoLine(
    label: String,
    value: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    color: Color
) {
    Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(24.dp))
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(label, color = AppColors.Muted, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
            Text(value, color = AppColors.Text, fontSize = 16.sp, lineHeight = 22.sp)
        }
    }
}

@Composable
private fun LegacyDetailScreen(selection: PlaceSelection, context: Context, onBack: () -> Unit) {
    val place = selection.place
    val accent = if (selection.isNotary) AppColors.Notary else AppColors.Primary
    val accentSoft = if (selection.isNotary) AppColors.NotarySoft else AppColors.PrimarySoft
    val status = OperatingSchedule.status(selection.isNotary)
    val statusColor = if (status.closed) AppColors.Muted else accent
    val statusSoft = if (status.closed) AppColors.Background else accentSoft
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, AppColors.Border, RoundedCornerShape(AppMetrics.CardRadius)),
        shape = RoundedCornerShape(AppMetrics.CardRadius),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                TextButton(onClick = onBack, modifier = Modifier.clip(CircleShape)) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null, tint = accent)
                }
                Text(
                    if (selection.isNotary) "Noter Detayı" else "Eczane Detayı",
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 20.sp,
                    color = AppColors.Text
                )
            }

            Row(verticalAlignment = Alignment.Top) {
                Surface(color = accentSoft, shape = CircleShape, contentColor = accent) {
                    Box(Modifier.size(58.dp), contentAlignment = Alignment.Center) {
                        Icon(
                            if (selection.isNotary) Icons.Default.Description else Icons.Default.LocalPharmacy,
                            contentDescription = null,
                            modifier = Modifier.size(31.dp)
                        )
                    }
                }
                Spacer(Modifier.width(14.dp))
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(place.name, fontWeight = FontWeight.ExtraBold, fontSize = 24.sp, color = AppColors.Text)
                    Text(listOf(place.district, place.city).filter { it.isNotBlank() }.joinToString(" / "), color = AppColors.Muted, fontSize = 16.sp)
                    Badge(
                        text = status.title,
                        color = statusColor,
                        softColor = statusSoft,
                        icon = { Icon(if (status.closed) Icons.Default.ErrorOutline else Icons.Default.CheckCircle, null, modifier = Modifier.size(15.dp)) }
                    )
                }
            }

            if (place.latitude != null && place.longitude != null) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(190.dp)
                        .clip(RoundedCornerShape(18.dp))
                        .border(1.dp, AppColors.Border, RoundedCornerShape(18.dp))
                ) {
                    NativeTileMap(
                        places = listOf(MapPlace(place, selection.isNotary)),
                        onPlaceSelected = {}
                    )
                }
            }

            DetailLine("Adres", place.address)
            DetailLine("Telefon", place.phone ?: "Telefon numarası yok")
            place.distanceKm?.let {
                DetailLine("Mesafe", String.format(Locale("tr", "TR"), "%.1f km", it))
            }

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                ActionButton(
                    modifier = Modifier.weight(1f),
                    text = "Ara",
                    icon = { Icon(Icons.Default.Call, null, modifier = Modifier.size(20.dp)) },
                    filled = true,
                    color = accent,
                    softColor = accentSoft
                ) { context.callPhone(place.phone) }
                ActionButton(
                    modifier = Modifier.weight(1f),
                    text = "Yol Tarifi",
                    icon = { Icon(Icons.Default.Navigation, null, modifier = Modifier.size(20.dp)) },
                    filled = false,
                    color = accent,
                    softColor = accentSoft
                ) { context.openDirections(place) }
            }
        }
    }
}

@Composable
private fun DetailLine(label: String, value: String) {
    Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
        Text(label, color = AppColors.Muted, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
        Text(value, color = AppColors.Text, fontSize = 16.sp, lineHeight = 22.sp)
    }
}

@Composable
private fun Badge(text: String, color: Color = AppColors.Primary, softColor: Color = AppColors.PrimarySoft, icon: @Composable () -> Unit) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(18.dp))
            .background(softColor)
            .padding(horizontal = 11.dp, vertical = 7.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Surface(color = color, shape = CircleShape, modifier = Modifier.size(18.dp), contentColor = Color.White) {
            Box(contentAlignment = Alignment.Center) { icon() }
        }
        Text(text, color = color, fontWeight = FontWeight.Bold, fontSize = 14.sp)
    }
}

@Composable
private fun ActionButton(
    modifier: Modifier = Modifier,
    text: String,
    icon: @Composable () -> Unit,
    filled: Boolean,
    color: Color = AppColors.Primary,
    softColor: Color = AppColors.PrimarySoft,
    onClick: () -> Unit
) {
    TextButton(
        onClick = onClick,
        modifier = modifier
            .height(52.dp)
            .clip(RoundedCornerShape(26.dp)),
        colors = ButtonDefaults.textButtonColors(
            containerColor = if (filled) color else softColor,
            contentColor = if (filled) Color.White else color
        )
    ) {
        icon()
        Spacer(Modifier.width(9.dp))
        Text(text, fontSize = 18.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun LoadingState(isNotary: Boolean = false) {
    Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(AppMetrics.CardRadius), colors = CardDefaults.cardColors(Color.White)) {
        Row(Modifier.padding(18.dp), verticalAlignment = Alignment.CenterVertically) {
            CircularProgressIndicator(Modifier.size(22.dp), strokeWidth = 2.dp, color = AppColors.Primary)
            Spacer(Modifier.width(12.dp))
            Text(if (isNotary) "En yakın noter bulunuyor..." else "En yakın eczane bulunuyor...")
        }
    }
}

@Composable
private fun MessageState(
    title: String,
    message: String,
    color: Color = AppColors.Primary,
    softColor: Color = AppColors.PrimarySoft,
    icon: @Composable () -> Unit
) {
    Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(AppMetrics.CardRadius), colors = CardDefaults.cardColors(Color.White)) {
        Column(
            Modifier.padding(22.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Surface(color = softColor, shape = CircleShape, contentColor = color) {
                Box(Modifier.size(42.dp), contentAlignment = Alignment.Center) { icon() }
            }
            Text(title, fontWeight = FontWeight.SemiBold)
            Text(message, color = AppColors.Muted, style = MaterialTheme.typography.bodyMedium)
        }
    }
}

@Composable
private fun MapScreen(places: List<MapPlace>, currentLocation: Location?, onPlaceSelected: (MapPlace) -> Unit) {
    val context = LocalContext.current
    var filter by remember { mutableStateOf(MapFilter.All) }
    var selectedMapPlace by remember { mutableStateOf<MapPlace?>(null) }
    var mapView by remember { mutableStateOf<MapView?>(null) }
    val visiblePlaces = remember(places, filter) {
        places.filter {
            when (filter) {
                MapFilter.All -> true
                MapFilter.Pharmacies -> !it.isNotary
                MapFilter.Notaries -> it.isNotary
            }
        }
    }
    val mapPlaces = remember(visiblePlaces) {
        visiblePlaces.forMapDisplay()
    }
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(730.dp)
            .clip(RoundedCornerShape(AppMetrics.CardRadius))
            .border(1.dp, AppColors.Border, RoundedCornerShape(AppMetrics.CardRadius))
    ) {
            OsmMap(
                places = mapPlaces,
                currentLocation = currentLocation,
                onMapReady = { mapView = it },
                onMarkerSelected = { selectedMapPlace = it }
            )

            Surface(
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .padding(top = 14.dp, start = 12.dp, end = 12.dp),
                color = Color.White.copy(alpha = 0.86f),
                shape = RoundedCornerShape(22.dp),
                shadowElevation = 1.dp
            ) {
                Row(
                    modifier = Modifier.padding(4.dp),
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    MapFilter.entries.forEach { item ->
                        FilterChipButton(
                            text = item.title,
                            selected = filter == item,
                            color = when (item) {
                                MapFilter.Notaries -> AppColors.Notary
                                else -> AppColors.Primary
                            },
                            onClick = {
                                filter = item
                                selectedMapPlace = null
                            }
                        )
                    }
                }
            }

            MapZoomControls(
                mapView = mapView,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(top = 68.dp, end = 12.dp)
            )

            if (mapPlaces.isEmpty()) {
                Surface(
                    modifier = Modifier
                        .align(Alignment.Center)
                        .padding(18.dp),
                    shape = RoundedCornerShape(18.dp),
                    color = Color.White.copy(alpha = 0.92f),
                    tonalElevation = 0.dp
                ) {
                    Column(
                        modifier = Modifier.padding(horizontal = 20.dp, vertical = 18.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Surface(color = AppColors.PrimarySoft, shape = CircleShape, contentColor = AppColors.Primary) {
                            Box(Modifier.size(44.dp), contentAlignment = Alignment.Center) {
                                Icon(Icons.Default.Map, contentDescription = null)
                            }
                        }
                        Text(
                            if (places.isEmpty()) "Harita için sonuç yok" else "Bu filtrede sonuç yok",
                            fontWeight = FontWeight.ExtraBold,
                            color = AppColors.Text,
                            fontSize = 18.sp
                        )
                        Text(
                            if (places.isEmpty()) "Önce eczane veya noter araması yapın." else "Hepsi filtresiyle tüm noktaları gösterin.",
                            color = AppColors.Muted,
                            fontSize = 14.sp,
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center
                        )
                    }
                }
            }

            selectedMapPlace?.let { selected ->
                MapPlacePopup(
                    item = selected,
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(start = 12.dp, end = 12.dp, bottom = 96.dp),
                    onDirections = { context.openDirections(selected.place) },
                    onDetail = { onPlaceSelected(selected) }
                )
            }
        }
}

@Composable
private fun MapZoomControls(mapView: MapView?, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(18.dp))
            .background(Color.White.copy(alpha = 0.92f))
            .border(1.dp, AppColors.Border.copy(alpha = 0.65f), RoundedCornerShape(18.dp)),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        TextButton(
            onClick = { mapView?.controller?.zoomIn() },
            modifier = Modifier.size(42.dp),
            contentPadding = ButtonDefaults.TextButtonContentPadding
        ) {
            Text("+", color = AppColors.Text, fontSize = 22.sp, fontWeight = FontWeight.Bold)
        }
        Box(
            Modifier
                .width(28.dp)
                .height(1.dp)
                .background(AppColors.Border)
        )
        TextButton(
            onClick = { mapView?.controller?.zoomOut() },
            modifier = Modifier.size(42.dp),
            contentPadding = ButtonDefaults.TextButtonContentPadding
        ) {
            Text("-", color = AppColors.Text, fontSize = 24.sp, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
@OptIn(ExperimentalComposeUiApi::class)
private fun OsmMap(
    places: List<MapPlace>,
    currentLocation: Location?,
    onMapReady: (MapView) -> Unit,
    onMarkerSelected: (MapPlace) -> Unit
) {
    val context = LocalContext.current
    val composeView = LocalView.current
    val placesKey = remember(places, currentLocation) {
        buildString {
            append(currentLocation?.latitude ?: "")
            append(":")
            append(currentLocation?.longitude ?: "")
            places.forEach { append("|${it.isNotary}-${it.place.id}-${it.place.latitude}-${it.place.longitude}") }
        }
    }
    var fittedKey by remember { mutableStateOf("") }

    AndroidView(
        modifier = Modifier
            .fillMaxSize()
            .pointerInteropFilter { event ->
                when (event.actionMasked) {
                    MotionEvent.ACTION_DOWN, MotionEvent.ACTION_MOVE -> composeView.parent?.requestDisallowInterceptTouchEvent(true)
                    MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> composeView.parent?.requestDisallowInterceptTouchEvent(false)
                }
                false
            },
        factory = { viewContext ->
            Configuration.getInstance().userAgentValue = viewContext.packageName
            val initialPoint = places.firstOrNull { it.place.latitude != null && it.place.longitude != null }?.let {
                GeoPoint(it.place.latitude ?: 41.0082, it.place.longitude ?: 28.9784)
            } ?: currentLocation?.let { GeoPoint(it.latitude, it.longitude) } ?: GeoPoint(41.0082, 28.9784)
            MapView(viewContext).apply {
                setTileSource(TileSourceFactory.MAPNIK)
                setMultiTouchControls(true)
                zoomController.setVisibility(CustomZoomButtonsController.Visibility.NEVER)
                setOnTouchListener { view, event ->
                    when (event.actionMasked) {
                        MotionEvent.ACTION_DOWN, MotionEvent.ACTION_MOVE -> view.parent?.requestDisallowInterceptTouchEvent(true)
                        MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> view.parent?.requestDisallowInterceptTouchEvent(false)
                    }
                    false
                }
                minZoomLevel = 5.0
                maxZoomLevel = 20.0
                isTilesScaledToDpi = false
                controller.setZoom(15.0)
                controller.setCenter(initialPoint)
                onResume()
                onMapReady(this)
            }
        },
        update = { map ->
            map.overlays.clear()

            places.forEach { item ->
                val lat = item.place.latitude
                val lng = item.place.longitude
                if (lat != null && lng != null) {
                    Marker(map).apply {
                        position = GeoPoint(lat, lng)
                        setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_CENTER)
                        icon = placeMarkerDrawable(context, item.isNotary)
                        title = item.place.name
                        setOnMarkerClickListener { marker, mapView ->
                            mapView.controller.animateTo(marker.position)
                            onMarkerSelected(item)
                            true
                        }
                        map.overlays.add(this)
                    }
                }
            }

            currentLocation?.let { loc ->
                Marker(map).apply {
                    position = GeoPoint(loc.latitude, loc.longitude)
                    setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_CENTER)
                    icon = currentLocationDrawable(context)
                    title = "Konumum"
                    map.overlays.add(this)
                }
            }

            if (fittedKey != placesKey) {
                fittedKey = placesKey
                map.post {
                    val includeCurrent = currentLocation?.let { location ->
                        places.any { item ->
                            val lat = item.place.latitude
                            val lng = item.place.longitude
                            lat != null && lng != null && geoDistanceKm(location.latitude, location.longitude, lat, lng) <= 25.0
                        }
                    } == true
                    fitMapToPlaces(map, places, currentLocation, includeCurrent = includeCurrent)
                }
            }

            map.invalidate()
        }
    )
}

@Composable
private fun MapPlacePopup(
    item: MapPlace,
    modifier: Modifier = Modifier,
    onDirections: () -> Unit,
    onDetail: () -> Unit
) {
    val place = item.place
    val color = if (item.isNotary) AppColors.Notary else AppColors.Primary
    val softColor = if (item.isNotary) AppColors.NotarySoft else AppColors.PrimarySoft
    val status = OperatingSchedule.status(item.isNotary)

    Surface(
        modifier = modifier.fillMaxWidth(),
        color = Color.White.copy(alpha = 0.95f),
        shape = RoundedCornerShape(22.dp),
        shadowElevation = 8.dp
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    if (item.isNotary) Icons.Default.Description else Icons.Default.LocalPharmacy,
                    contentDescription = null,
                    tint = color,
                    modifier = Modifier.size(26.dp)
                )
                Spacer(Modifier.width(10.dp))
                Text(
                    place.name,
                    modifier = Modifier.weight(1f),
                    color = AppColors.Text,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 20.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Surface(color = softColor, shape = RoundedCornerShape(18.dp), contentColor = color) {
                    Row(
                        modifier = Modifier.padding(horizontal = 11.dp, vertical = 7.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(5.dp)
                    ) {
                        Icon(Icons.Default.CheckCircle, contentDescription = null, modifier = Modifier.size(16.dp))
                        Text(status.title, fontWeight = FontWeight.ExtraBold, fontSize = 13.sp)
                    }
                }
            }

            Text(
                place.address,
                color = AppColors.Muted,
                fontSize = 16.sp,
                lineHeight = 21.sp,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                ActionButton(
                    modifier = Modifier.weight(1f),
                    text = "Yol Tarifi Al",
                    icon = { Icon(Icons.Default.Navigation, null, modifier = Modifier.size(20.dp)) },
                    filled = true,
                    color = color,
                    softColor = softColor,
                    onClick = onDirections
                )
                ActionButton(
                    modifier = Modifier.weight(1f),
                    text = "Detay",
                    icon = { },
                    filled = false,
                    color = color,
                    softColor = softColor,
                    onClick = onDetail
                )
            }
        }
    }
}

private fun placeMarkerDrawable(context: Context, isNotary: Boolean): BitmapDrawable {
    val color = if (isNotary) android.graphics.Color.rgb(0, 166, 166) else android.graphics.Color.rgb(196, 30, 58)
    val bitmap = Bitmap.createBitmap(92, 92, Bitmap.Config.ARGB_8888)
    val canvas = AndroidCanvas(bitmap)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    paint.color = android.graphics.Color.argb(70, 0, 0, 0)
    canvas.drawCircle(49f, 51f, 35f, paint)
    paint.color = android.graphics.Color.WHITE
    canvas.drawCircle(46f, 46f, 35f, paint)
    paint.color = color
    canvas.drawCircle(46f, 46f, 28f, paint)

    paint.color = android.graphics.Color.WHITE
    paint.strokeWidth = 6f
    paint.strokeCap = Paint.Cap.ROUND
    if (isNotary) {
        paint.style = Paint.Style.STROKE
        canvas.drawRoundRect(RectF(34f, 28f, 58f, 64f), 3f, 3f, paint)
        canvas.drawLine(40f, 40f, 52f, 40f, paint)
        canvas.drawLine(40f, 50f, 52f, 50f, paint)
    } else {
        paint.style = Paint.Style.FILL
        canvas.drawRoundRect(RectF(30f, 35f, 62f, 61f), 5f, 5f, paint)
        canvas.drawRect(42f, 26f, 50f, 70f, paint)
        canvas.drawRect(24f, 44f, 68f, 52f, paint)
    }

    return BitmapDrawable(context.resources, bitmap)
}

private fun currentLocationDrawable(context: Context): BitmapDrawable {
    val bitmap = Bitmap.createBitmap(64, 64, Bitmap.Config.ARGB_8888)
    val canvas = AndroidCanvas(bitmap)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    paint.color = android.graphics.Color.WHITE
    canvas.drawCircle(32f, 32f, 22f, paint)
    paint.color = android.graphics.Color.rgb(35, 116, 255)
    canvas.drawCircle(32f, 32f, 14f, paint)
    paint.style = Paint.Style.STROKE
    paint.strokeWidth = 4f
    paint.color = android.graphics.Color.argb(80, 35, 116, 255)
    canvas.drawCircle(32f, 32f, 25f, paint)
    return BitmapDrawable(context.resources, bitmap)
}

private fun fitMapToPlaces(
    map: MapView,
    places: List<MapPlace>,
    currentLocation: Location?,
    includeCurrent: Boolean
) {
    val points = buildList {
        places.forEach { item ->
            val lat = item.place.latitude
            val lng = item.place.longitude
            if (lat != null && lng != null) add(GeoPoint(lat, lng))
        }
        if (includeCurrent) {
            currentLocation?.let { add(GeoPoint(it.latitude, it.longitude)) }
        }
    }

    when {
        points.size >= 2 -> {
            val north = points.maxOf { it.latitude }
            val south = points.minOf { it.latitude }
            val east = points.maxOf { it.longitude }
            val west = points.minOf { it.longitude }
            map.zoomToBoundingBox(BoundingBox(north, east, south, west), true, 90)
        }
        points.size == 1 -> {
            map.controller.setZoom(16.0)
            map.controller.animateTo(points.first())
        }
    }
}

@Composable
private fun InteractiveTileMap(places: List<MapPlace>, onPlaceSelected: (MapPlace) -> Unit) {
    val coordinatePlaces = places.filter { it.place.latitude != null && it.place.longitude != null }
    val density = LocalDensity.current

    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFE5ECEF))
    ) {
        val widthPx = constraints.maxWidth.toDouble()
        val heightPx = constraints.maxHeight.toDouble()
        var zoom by remember { mutableStateOf(13) }
        var centerWorldX by remember { mutableStateOf(longitudeToWorldPixel(28.9784, zoom)) }
        var centerWorldY by remember { mutableStateOf(latitudeToWorldPixel(41.0082, zoom)) }
        val placesKey = remember(coordinatePlaces) {
            coordinatePlaces.joinToString("|") { "${it.place.id}:${it.place.latitude}:${it.place.longitude}" }
        }

        LaunchedEffect(placesKey, widthPx, heightPx) {
            if (widthPx > 0.0 && heightPx > 0.0) {
                zoom = chooseMapZoom(coordinatePlaces, widthPx, heightPx)
                val center = mapCenterWorld(coordinatePlaces, zoom)
                centerWorldX = center.first
                centerWorldY = center.second
            }
        }

        fun clampCenter() {
            val world = 256.0 * 2.0.pow(zoom)
            centerWorldX = ((centerWorldX % world) + world) % world
            centerWorldY = centerWorldY.coerceIn(0.0, world)
        }

        fun zoomTo(nextZoom: Int, anchorX: Float, anchorY: Float) {
            val clampedZoom = nextZoom.coerceIn(10, 17)
            if (clampedZoom == zoom || widthPx <= 0.0 || heightPx <= 0.0) return
            val beforeX = centerWorldX + anchorX - widthPx / 2.0
            val beforeY = centerWorldY + anchorY - heightPx / 2.0
            val scale = 2.0.pow(clampedZoom - zoom)
            centerWorldX = beforeX * scale - anchorX + widthPx / 2.0
            centerWorldY = beforeY * scale - anchorY + heightPx / 2.0
            zoom = clampedZoom
            clampCenter()
        }

        val tileSize = with(density) { 256.toDp() }
        val worldTileCount = 1 shl zoom
        val minTileX = floor((centerWorldX - widthPx / 2.0) / 256.0).toInt() - 1
        val maxTileX = ceil((centerWorldX + widthPx / 2.0) / 256.0).toInt() + 1
        val minTileY = floor((centerWorldY - heightPx / 2.0) / 256.0).toInt() - 1
        val maxTileY = ceil((centerWorldY + heightPx / 2.0) / 256.0).toInt() + 1
        val tiles = remember(zoom, minTileX, maxTileX, minTileY, maxTileY, centerWorldX, centerWorldY, widthPx, heightPx) {
            (minTileY..maxTileY).flatMap { tileY ->
                (minTileX..maxTileX).mapNotNull { tileX ->
                    if (tileY !in 0 until worldTileCount) {
                        null
                    } else {
                        val wrappedX = ((tileX % worldTileCount) + worldTileCount) % worldTileCount
                        MapTile(
                            x = wrappedX,
                            y = tileY,
                            zoom = zoom,
                            left = widthPx / 2.0 + tileX * 256.0 - centerWorldX,
                            top = heightPx / 2.0 + tileY * 256.0 - centerWorldY
                        )
                    }
                }
            }
        }
        val markerPoints = coordinatePlaces.map { item ->
            val place = item.place
            val left = widthPx / 2.0 + longitudeToWorldPixel(place.longitude ?: 28.9784, zoom) - centerWorldX
            val top = heightPx / 2.0 + latitudeToWorldPixel(place.latitude ?: 41.0082, zoom) - centerWorldY
            item to androidx.compose.ui.geometry.Offset(left.toFloat(), top.toFloat())
        }

        Box(
            modifier = Modifier
                .fillMaxSize()
                .pointerInput(zoom, centerWorldX, centerWorldY, widthPx, heightPx) {
                    detectTransformGestures { centroid, pan, zoomChange, _ ->
                        centerWorldX -= pan.x
                        centerWorldY -= pan.y
                        when {
                            zoomChange > 1.08f -> zoomTo(zoom + 1, centroid.x, centroid.y)
                            zoomChange < 0.92f -> zoomTo(zoom - 1, centroid.x, centroid.y)
                            else -> clampCenter()
                        }
                    }
                }
                .pointerInput(markerPoints, zoom, centerWorldX, centerWorldY) {
                    detectTapGestures(
                        onDoubleTap = { tap -> zoomTo(zoom + 1, tap.x, tap.y) },
                        onTap = { tap ->
                            markerPoints
                                .map { (item, point) ->
                                    val dx = tap.x - point.x
                                    val dy = tap.y - point.y
                                    item to (dx * dx + dy * dy)
                                }
                                .minByOrNull { it.second }
                                ?.takeIf { it.second <= 76f * 76f }
                                ?.let { onPlaceSelected(it.first) }
                        }
                    )
                }
        ) {
            Canvas(Modifier.fillMaxSize()) {
                drawRect(Color(0xFFDDECEF))
                drawCircle(Color(0xFFEAF3E7), radius = size.minDimension * 0.44f, center = androidx.compose.ui.geometry.Offset(size.width * 0.78f, size.height * 0.20f))
                drawCircle(Color(0xFFEAF3E7), radius = size.minDimension * 0.36f, center = androidx.compose.ui.geometry.Offset(size.width * 0.16f, size.height * 0.82f))
            }

            tiles.forEach { tile ->
                MapTileImage(
                    url = tile.url,
                    modifier = Modifier
                        .size(tileSize)
                        .offset {
                            IntOffset(
                                x = tile.left.roundToInt(),
                                y = tile.top.roundToInt()
                            )
                        }
                )
            }

            markerPoints.forEach { (item, point) ->
                Box(
                    modifier = Modifier
                        .offset { IntOffset(point.x.roundToInt() - 68, point.y.roundToInt() - 29) }
                        .width(136.dp)
                        .height(74.dp)
                        .zIndex(2f),
                    contentAlignment = Alignment.TopCenter
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        Box(
                            modifier = Modifier
                                .size(30.dp)
                                .clip(CircleShape)
                                .background(if (item.isNotary) AppColors.Notary else AppColors.Primary)
                                .border(3.dp, Color.White, CircleShape)
                        )
                        Text(
                            text = item.place.shortMapName(),
                            modifier = Modifier
                                .clip(RoundedCornerShape(9.dp))
                                .background(Color.White.copy(alpha = 0.9f))
                                .padding(horizontal = 5.dp, vertical = 2.dp),
                            color = AppColors.Text,
                            fontSize = 8.sp,
                            fontWeight = FontWeight.ExtraBold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
            }

            Column(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(10.dp)
                    .clip(RoundedCornerShape(18.dp))
                    .background(Color.White.copy(alpha = 0.94f))
                    .border(1.dp, AppColors.Border, RoundedCornerShape(18.dp))
                    .zIndex(4f)
            ) {
                MapZoomButton("+") { zoomTo(zoom + 1, (widthPx / 2.0).toFloat(), (heightPx / 2.0).toFloat()) }
                Box(
                    Modifier
                        .width(38.dp)
                        .height(1.dp)
                        .background(AppColors.Border)
                )
                MapZoomButton("-") { zoomTo(zoom - 1, (widthPx / 2.0).toFloat(), (heightPx / 2.0).toFloat()) }
            }
        }
    }
}

@Composable
private fun MapZoomButton(text: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(38.dp)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(text, color = AppColors.Text, fontWeight = FontWeight.ExtraBold, fontSize = 22.sp)
    }
}

private class MapBridge(private val onMarkerClick: (Int) -> Unit) {
    private val mainHandler = Handler(Looper.getMainLooper())

    @JavascriptInterface
    fun select(index: Int) {
        mainHandler.post { onMarkerClick(index) }
    }
}

@Composable
private fun FilterChipButton(text: String, selected: Boolean, color: Color, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(18.dp))
            .background(if (selected) color.copy(alpha = 0.14f) else Color.White.copy(alpha = 0.62f))
            .border(1.dp, if (selected) color.copy(alpha = 0.55f) else AppColors.Border.copy(alpha = 0.65f), RoundedCornerShape(18.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 9.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(5.dp)
    ) {
        if (selected) {
            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = color, modifier = Modifier.size(14.dp))
        }
        Text(text, color = if (selected) color else AppColors.Text, fontWeight = FontWeight.Bold, fontSize = 11.sp)
    }
}

@Composable
private fun NativeTileMap(places: List<MapPlace>, onPlaceSelected: (MapPlace) -> Unit) {
    val coordinatePlaces = places.filter { it.place.latitude != null && it.place.longitude != null }
    val density = LocalDensity.current

    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFE5ECEF))
    ) {
        val widthPx = constraints.maxWidth.toDouble()
        val heightPx = constraints.maxHeight.toDouble()
        val zoom = remember(coordinatePlaces, widthPx, heightPx) {
            chooseMapZoom(coordinatePlaces, widthPx, heightPx)
        }
        val center = remember(coordinatePlaces, zoom) {
            mapCenterWorld(coordinatePlaces, zoom)
        }
        val centerWorldX = center.first
        val centerWorldY = center.second
        val tileSize = with(density) { 256.toDp() }
        val minTileX = floor((centerWorldX - widthPx / 2.0) / 256.0).toInt() - 1
        val maxTileX = ceil((centerWorldX + widthPx / 2.0) / 256.0).toInt() + 1
        val minTileY = floor((centerWorldY - heightPx / 2.0) / 256.0).toInt() - 1
        val maxTileY = ceil((centerWorldY + heightPx / 2.0) / 256.0).toInt() + 1
        val worldTileCount = 1 shl zoom
        val tiles = remember(zoom, minTileX, maxTileX, minTileY, maxTileY, centerWorldX, centerWorldY, widthPx, heightPx) {
            (minTileY..maxTileY).flatMap { tileY ->
                (minTileX..maxTileX).mapNotNull { tileX ->
                    if (tileY !in 0 until worldTileCount) {
                        null
                    } else {
                        val wrappedX = ((tileX % worldTileCount) + worldTileCount) % worldTileCount
                        MapTile(
                            x = wrappedX,
                            y = tileY,
                            zoom = zoom,
                            left = widthPx / 2.0 + tileX * 256.0 - centerWorldX,
                            top = heightPx / 2.0 + tileY * 256.0 - centerWorldY
                        )
                    }
                }
            }
        }
        val markerPoints = coordinatePlaces.map { item ->
            val place = item.place
            val left = widthPx / 2.0 + longitudeToWorldPixel(place.longitude ?: 28.9784, zoom) - centerWorldX
            val top = heightPx / 2.0 + latitudeToWorldPixel(place.latitude ?: 41.0082, zoom) - centerWorldY
            item to androidx.compose.ui.geometry.Offset(left.toFloat(), top.toFloat())
        }

        Box(
            modifier = Modifier
                .fillMaxSize()
                .pointerInput(markerPoints) {
                    detectTapGestures { tap ->
                        markerPoints
                            .map { (item, pointDp) ->
                                val point = androidx.compose.ui.geometry.Offset(pointDp.x, pointDp.y)
                                val dx = tap.x - point.x
                                val dy = tap.y - point.y
                                item to (dx * dx + dy * dy)
                            }
                            .minByOrNull { it.second }
                            ?.takeIf { it.second <= 84f * 84f }
                            ?.let { onPlaceSelected(it.first) }
                    }
                }
        ) {
            Canvas(Modifier.fillMaxSize()) {
                drawRect(Color(0xFFDDECEF))
                drawCircle(Color(0xFFEAF3E7), radius = size.minDimension * 0.44f, center = androidx.compose.ui.geometry.Offset(size.width * 0.78f, size.height * 0.20f))
                drawCircle(Color(0xFFEAF3E7), radius = size.minDimension * 0.36f, center = androidx.compose.ui.geometry.Offset(size.width * 0.16f, size.height * 0.82f))
                val roadColor = Color.White.copy(alpha = 0.82f)
                val majorRoad = Color(0xFFF1C978).copy(alpha = 0.76f)
                listOf(0.18f, 0.38f, 0.58f, 0.78f).forEach { y ->
                    val path = Path().apply {
                        moveTo(-20f, size.height * y)
                        cubicTo(size.width * 0.25f, size.height * (y - 0.08f), size.width * 0.62f, size.height * (y + 0.10f), size.width + 20f, size.height * (y - 0.02f))
                    }
                    drawPath(path, roadColor, style = Stroke(width = 9f))
                }
                listOf(0.24f, 0.48f, 0.72f).forEach { x ->
                    val path = Path().apply {
                        moveTo(size.width * x, -20f)
                        cubicTo(size.width * (x + 0.08f), size.height * 0.24f, size.width * (x - 0.10f), size.height * 0.66f, size.width * (x + 0.04f), size.height + 20f)
                    }
                    drawPath(path, roadColor, style = Stroke(width = 7f))
                }
                drawLine(majorRoad, androidx.compose.ui.geometry.Offset(-10f, size.height * 0.34f), androidx.compose.ui.geometry.Offset(size.width + 10f, size.height * 0.28f), strokeWidth = 11f)
                drawLine(majorRoad, androidx.compose.ui.geometry.Offset(size.width * 0.10f, size.height + 10f), androidx.compose.ui.geometry.Offset(size.width * 0.86f, -10f), strokeWidth = 8f)
            }

            tiles.forEach { tile ->
                MapTileImage(
                    url = tile.url,
                    modifier = Modifier
                        .size(tileSize)
                        .offset {
                            IntOffset(
                                x = tile.left.roundToInt(),
                                y = tile.top.roundToInt()
                            )
                        }
                )
            }

            markerPoints.forEach { (item, pointDp) ->
                Box(
                    modifier = Modifier
                        .offset { IntOffset(pointDp.x.roundToInt() - 48, pointDp.y.roundToInt() - 28) }
                        .width(96.dp)
                        .height(72.dp)
                        .zIndex(2f),
                    contentAlignment = Alignment.TopCenter
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Box(
                            modifier = Modifier
                                .size(28.dp)
                                .clip(CircleShape)
                                .background(if (item.isNotary) AppColors.Notary else AppColors.Primary)
                                .border(3.dp, Color.White, CircleShape)
                        )
                        Text(
                            text = item.place.shortMapName(),
                            modifier = Modifier
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.White.copy(alpha = 0.84f))
                                .padding(horizontal = 4.dp, vertical = 2.dp),
                            color = AppColors.Text,
                            fontSize = 8.sp,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MapTileImage(url: String, modifier: Modifier = Modifier) {
    var image by remember(url) { mutableStateOf<androidx.compose.ui.graphics.ImageBitmap?>(null) }
    LaunchedEffect(url) {
        image = withContext(Dispatchers.IO) {
            runCatching {
                val connection = (URL(url).openConnection() as HttpURLConnection).apply {
                    setRequestProperty("User-Agent", "NobetcimMobile/1.0 Android")
                    setRequestProperty("Referer", "https://nobetcim.info/")
                    connectTimeout = 10_000
                    readTimeout = 10_000
                }
                connection.inputStream.use { BitmapFactory.decodeStream(it).asImageBitmap() }
            }.getOrNull()
        }
    }

    if (image != null) {
        Image(
            bitmap = image!!,
            contentDescription = null,
            modifier = modifier,
            contentScale = ContentScale.FillBounds
        )
    } else {
        Box(modifier.background(Color(0xFFE8EEF1)))
    }
}

@Composable
private fun MoreScreen(onOpenPharmacies: () -> Unit, onOpenNotaries: () -> Unit, onOpenMap: () -> Unit) {
    var selectedLegal by remember { mutableStateOf<LegalPage?>(null) }
    selectedLegal?.let { page ->
        LegalPageView(page = page, onBack = { selectedLegal = null })
        return
    }

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("Daha Fazla", fontWeight = FontWeight.ExtraBold, fontSize = 28.sp, color = AppColors.Text)

        MoreSection {
            MoreRow("Eczaneler", Icons.Default.LocalPharmacy, onOpenPharmacies, AppColors.Primary, AppColors.PrimarySoft)
            MoreDivider()
            MoreRow("Noterler", Icons.Default.Description, onOpenNotaries, AppColors.Notary, AppColors.NotarySoft)
            MoreDivider()
            MoreRow("Harita", Icons.Default.Map, onOpenMap)
        }

        MoreSectionTitle("Yasal")
        MoreSection {
            MoreInfoRow("Gizlilik Politikası") { selectedLegal = LegalPage.privacyPolicy }
            MoreDivider()
            MoreInfoRow("Kullanım Koşulları") { selectedLegal = LegalPage.terms }
            MoreDivider()
            MoreInfoRow("KVKK") { selectedLegal = LegalPage.kvkk }
        }

        MoreSectionTitle("Uygulama")
        MoreSection {
            MoreLabeledRow("Sürüm", "1.0")
            MoreDivider()
            MoreLabeledRow("İletişim", "destek@nobetcim.info")
        }

        MoreSectionTitle("Bilgilendirme")
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, AppColors.Border, RoundedCornerShape(16.dp)),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White),
            elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
        ) {
            Text(
                "Gösterilen kayıtlar kaynak verilere dayanır; adres, mesafe ve iletişim bilgileri hatalı veya güncel olmayabilir. Gitmeden önce ilgili işletmeyi aramanız önerilir.",
                modifier = Modifier.padding(16.dp),
                color = AppColors.Muted,
                fontSize = 13.sp,
                lineHeight = 18.sp
            )
        }
    }
}

@Composable
private fun LegalPageView(page: LegalPage, onBack: () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Surface(color = Color.White, shape = CircleShape, contentColor = AppColors.Primary) {
                Box(
                    Modifier
                        .size(48.dp)
                        .clickable(onClick = onBack),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null, modifier = Modifier.size(26.dp))
                }
            }
            Spacer(Modifier.width(12.dp))
            Text(page.title, fontWeight = FontWeight.ExtraBold, fontSize = 22.sp, color = AppColors.Text)
        }

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, AppColors.Border, RoundedCornerShape(AppMetrics.CardRadius)),
            shape = RoundedCornerShape(AppMetrics.CardRadius),
            colors = CardDefaults.cardColors(containerColor = Color.White),
            elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
        ) {
            Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Text(page.lastUpdated, color = AppColors.Muted, fontSize = 13.sp, lineHeight = 18.sp)
                page.sections.forEach { section ->
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(section.heading, color = AppColors.Text, fontWeight = FontWeight.ExtraBold, fontSize = 17.sp)
                        section.paragraphs.forEach { paragraph ->
                            Text(paragraph, color = AppColors.Text, fontSize = 14.sp, lineHeight = 21.sp)
                        }
                        section.bullets.forEach { bullet ->
                            Text("- $bullet", color = AppColors.Text, fontSize = 14.sp, lineHeight = 21.sp)
                        }
                    }
                }
                page.footer?.let {
                    Text(it, color = AppColors.Muted, fontSize = 13.sp, lineHeight = 18.sp)
                }
            }
        }
    }
}

@Composable
private fun MoreSection(content: @Composable ColumnScope.() -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, AppColors.Border, RoundedCornerShape(16.dp)),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(content = content)
    }
}

@Composable
private fun MoreSectionTitle(text: String) {
    Text(
        text,
        modifier = Modifier.padding(start = 4.dp, bottom = 0.dp),
        color = AppColors.Muted,
        fontSize = 13.sp,
        fontWeight = FontWeight.SemiBold
    )
}

@Composable
private fun MoreDivider() {
    Box(
        Modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(AppColors.Border.copy(alpha = 0.65f))
    )
}

@Composable
private fun MoreRow(
    text: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: () -> Unit,
    color: Color = AppColors.Primary,
    softColor: Color = AppColors.PrimarySoft
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(color = softColor, shape = CircleShape, contentColor = color) {
            Box(Modifier.size(34.dp), contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, modifier = Modifier.size(19.dp))
            }
        }
        Spacer(Modifier.width(12.dp))
        Text(text, fontWeight = FontWeight.SemiBold, color = AppColors.Text)
    }
}

@Composable
private fun MoreInfoRow(text: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text, modifier = Modifier.weight(1f), color = AppColors.Text, fontWeight = FontWeight.Medium)
        Icon(Icons.Default.KeyboardArrowDown, contentDescription = null, tint = AppColors.Muted, modifier = Modifier.size(20.dp))
    }
}

@Composable
private fun MoreLabeledRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, color = AppColors.Text, fontWeight = FontWeight.Medium)
        Spacer(Modifier.weight(1f))
        Text(value, color = AppColors.Muted, fontSize = 14.sp)
    }
}

private data class LegalSection(
    val heading: String,
    val paragraphs: List<String> = emptyList(),
    val bullets: List<String> = emptyList()
)

private data class LegalPage(
    val title: String,
    val lastUpdated: String,
    val sections: List<LegalSection>,
    val footer: String? = null
) {
    companion object {
        val privacyPolicy = LegalPage(
            title = "Gizlilik Politikası",
            lastUpdated = "Son güncelleme: 28 Mart 2026",
            sections = listOf(
                LegalSection(
                    heading = "1. Veri sorumlusu ve kapsam",
                    paragraphs = listOf("Bu politika, Nöbetçim Cebinde iOS uygulaması ve nobetcim.info alan adı altındaki hizmetler için geçerlidir. Platform; yerel hizmet ve işletme bilgilerine (bugün ağırlıklı olarak nöbetçi eczaneler) erişimi kolaylaştırmayı amaçlar.")
                ),
                LegalSection(
                    heading = "2. Toplanan veriler ve amaçlar",
                    bullets = listOf(
                        "Cihazda saklanan veriler: Son kullanılan il ve ilçe seçimleri ile günlük liste önbelleği yalnızca cihazınızda tutulur; kullanıcı hesabı oluşturulmaz.",
                        "Konum verisi: Yalnızca konum izni vermeniz halinde yakın kayıtları sıralamak için kullanılır. Koordinatlar, yakındaki kayıtları sorgulamak için hizmet sağlayıcısına iletilebilir.",
                        "Teknik veriler: Barındırma ve API sağlayıcıları standart sunucu günlükleri (IP adresi, istek zamanı vb.) üretebilir; bu, güvenlik ve işletim için yaygın bir uygulamadır."
                    )
                ),
                LegalSection(
                    heading = "3. Google reklamları ve ölçüm",
                    paragraphs = listOf(
                        "Uygulamada Google Mobile Ads kullanılabilir. Google, reklamları göstermek ve kişiselleştirmek için tanımlayıcılar ve benzeri teknolojiler kullanabilir. Kişiselleştirilmiş reklamcılık hakkında bilgi için Google Reklam ayarlarını (google.com/settings/ads) ziyaret edebilirsiniz.",
                        "Avrupa Ekonomik Alanı veya İngiltere’deyseniz, reklam ortaklarının veri işlemleri için yürürlükteki rıza ve bilgilendirme kurallarına uygun hareket edilmesi gerekir; uygulama içi rıza akışları üretim sürümünde Google UMP ile yönetilir."
                    )
                ),
                LegalSection(
                    heading = "4. Harita ve harici içerik",
                    paragraphs = listOf("Harita ve yol tarifi Apple Haritalar üzerinden açılır; harita sağlayıcısının kendi gizlilik uygulamaları geçerlidir.")
                ),
                LegalSection(
                    heading = "5. KVKK kapsamında haklarınız",
                    paragraphs = listOf(
                        "6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında; verilerinizin işlenip işlenmediğini öğrenme, düzeltilmesini veya silinmesini isteme, işlenme amacını öğrenme ve mevzuata aykırı işleme halinde şikâyet hakkına sahipsiniz. Cihazınızda tutulan tercih ve önbellek verilerini uygulamayı kaldırarak veya ilgili ayarlardan silebilirsiniz.",
                        "Veri sorumlusu bilgileri ve başvuru yolları için uygulama içindeki KVKK aydınlatma metnine bakınız."
                    )
                ),
                LegalSection(
                    heading = "6. Politika güncellemeleri",
                    paragraphs = listOf("Bu metin zaman zaman güncellenebilir. Önemli değişikliklerde uygulama veya web sitesinde yeni tarih gösterilir.")
                )
            )
        )

        val terms = LegalPage(
            title = "Kullanım Koşulları",
            lastUpdated = "Son güncelleme: 3 Nisan 2026",
            sections = listOf(
                LegalSection("1. Taraflar ve kabul", paragraphs = listOf("Bu kullanım koşulları, Nöbetçim Cebinde iOS uygulamasını ve nobetcim.info hizmetlerini kullanan herkes için geçerlidir. Uygulamayı kullanmaya devam etmeniz, bu koşulları okuduğunuzu ve kabul ettiğinizi ifade eder.")),
                LegalSection("2. Hizmetin niteliği", paragraphs = listOf("Uygulama; yerel hizmet ve işletme bilgilerine erişimi kolaylaştırmak amacıyla “olduğu gibi” sunulur. Hizmet sürekliliği, güncelliği veya belirli bir sonucun elde edilmesi garanti edilmez.")),
                LegalSection("3. Bilgilerin doğruluğu ve sorumluluk reddi", paragraphs = listOf("Listeler, mesafeler ve iletişim bilgileri otomatik işleme veya üçüncü taraf kaynaklara dayanabilir. Yanlış, eksik veya güncelliğini yitirmiş veriler oluşabilir. Tıbbi acil durumlarda 112 ve yetkili sağlık kuruluşlarına başvurunuz. İlaç ve tedavi için eczacı veya hekiminize danışınız.", "Nöbetçim Cebinde, bu uygulamadaki bilgilere dayanarak yapılan işlemlerden doğrudan veya dolaylı zararlardan sorumlu tutulamaz.")),
                LegalSection("4. Kullanıcı yükümlülükleri", bullets = listOf("Uygulamayı yürürlükteki mevzuata ve üçüncü kişi haklarına aykırı amaçlarla kullanmamayı,", "Otomatik tarama, aşırı yük oluşturma veya güvenliği tehdit eden faaliyetlerde bulunmamayı,", "Telif hakkı, ticari marka ve kişilik haklarına saygı göstermeyi kabul edersiniz.")),
                LegalSection("5. Fikri mülkiyet", paragraphs = listOf("Uygulama tasarımı, metinler ve yazılım bileşenleri ilgili mevzuat kapsamında korunabilir. İzinsiz çoğaltma, dağıtma veya ticari kullanım yasaktır.")),
                LegalSection("6. Üçüncü taraf bağlantıları ve reklamlar", paragraphs = listOf("Uygulamada Google reklamları veya diğer üçüncü taraf içerikleri yer alabilir. Bu hizmetlerin koşulları ve gizlilik uygulamaları ilgili sağlayıcılara aittir; ayrıntılar için gizlilik politikamıza bakınız.")),
                LegalSection("7. Değişiklikler ve uygulanacak hukuk", paragraphs = listOf("Bu koşullar güncellenebilir; önemli değişikliklerde tarih yenilenir. Uyuşmazlıklarda Türkiye Cumhuriyeti kanunları geçerlidir (tüketici işlemlerinde tüketicinin hakları saklıdır)."))
            )
        )

        val kvkk = LegalPage(
            title = "KVKK Aydınlatma Metni",
            lastUpdated = "6698 sayılı Kişisel Verilerin Korunması Kanunu — Son güncelleme: 3 Nisan 2026",
            sections = listOf(
                LegalSection("Veri sorumlusu", paragraphs = listOf("Nöbetçim Cebinde uygulamasının yürütücüsü, 6698 sayılı Kanun (“KVKK”) uyarınca veri sorumlusu sıfatıyla kişisel verilerinizi aşağıda özetlenen çerçevede işleyebilir. Başvurular için: destek@nobetcim.info")),
                LegalSection("İşlenen kişisel veriler", bullets = listOf("Konum verisi (isteğe bağlı): İzin ile enlem/boylam; yakın kayıt sorgularında kullanılır. İzin verilmezse il ve ilçe seçimi ile arama yapılabilir.", "Cihaz verisi: Son arama tercihleri ve günlük önbellek çoğunlukla yalnızca cihazınızda saklanır.", "Teknik veri: IP adresi, istek zamanı gibi veriler barındırma ve güvenlik süreçlerinde işlenebilir.", "Reklam tanımlayıcıları: Ölçüm ve reklam için üçüncü taraflarca (ör. Google) kullanılabilir.")),
                LegalSection("İşleme amaçları ve hukuki sebepler", paragraphs = listOf("Veriler; hizmetin sunulması, kullanıcı deneyiminin iyileştirilmesi, güvenlik, yasal yükümlülüklerin yerine getirilmesi ve — açık rıza veya meşru menfaat çerçevesinde — reklam gösterimi amaçlarıyla işlenebilir. Ayrıntılı açıklama için gizlilik politikamız bu aydınlatma metninin eki sayılır.")),
                LegalSection("Aktarım", paragraphs = listOf("Veriler; barındırma, harita ve reklam sağlayıcıları gibi yurt içi veya yurt dışı hizmet sağlayıcılara, hizmetin gerektirdiği ölçüde aktarılabilir.")),
                LegalSection("KVKK madde 11 kapsamındaki haklarınız", paragraphs = listOf("Kişisel verilerinizin işlenip işlenmediğini öğrenme, işlenmişse bilgi talep etme, işlenme amacını ve amaca uygun kullanılıp kullanılmadığını öğrenme, yurt içinde veya yurt dışında aktarıldığı üçüncü kişileri bilme, eksik veya yanlış işlenmişse düzeltilmesini isteme, KVKK’da öngörülen şartlar çerçevesinde silinmesini veya yok edilmesini isteme, otomatik sistemlerle aleyhinize sonuç doğmasına itiraz etme ve kanuna aykırı işleme sebebiyle zarar halinde tazminat talep etme haklarına sahipsiniz.", "Başvurularınızı veri sorumlusuna yazılı olarak veya Kişisel Verileri Koruma Kurulu’nun öngördüğü diğer yöntemlerle iletebilirsiniz. Şikâyetlerinizi Kurul’a iletme hakkınız saklıdır."))
            ),
            footer = "Bu metin genel bilgilendirme amaçlıdır; somut uyuşmazlıklarda hukuki danışmanlık alınız."
        )
    }
}

@Composable
private fun BottomTabBar(selected: MainTab, onSelected: (MainTab) -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .navigationBarsPadding()
            .padding(horizontal = 24.dp, vertical = 10.dp),
        contentAlignment = Alignment.Center
    ) {
        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(42.dp))
                .background(Color.White.copy(alpha = 0.96f))
                .border(1.dp, AppColors.Border.copy(alpha = 0.5f), RoundedCornerShape(42.dp))
                .padding(horizontal = 8.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            BottomTabItem("Eczaneler", Icons.Default.LocalPharmacy, selected = selected == MainTab.Pharmacies) { onSelected(MainTab.Pharmacies) }
            BottomTabItem("Noterler", Icons.Default.Description, selected = selected == MainTab.Notaries) { onSelected(MainTab.Notaries) }
            BottomTabItem("Harita", Icons.Default.Map, selected = selected == MainTab.Map) { onSelected(MainTab.Map) }
            BottomTabItem("Daha Fazla", Icons.Default.MoreHoriz, selected = selected == MainTab.More) { onSelected(MainTab.More) }
        }
    }
}

@Composable
private fun BottomTabItem(text: String, icon: androidx.compose.ui.graphics.vector.ImageVector, selected: Boolean, onClick: () -> Unit) {
    val selectedColor = if (text == "Noterler") AppColors.Notary else AppColors.Primary
    val selectedSoft = if (text == "Noterler") AppColors.NotarySoft else AppColors.PrimarySoft
    val color = if (selected) selectedColor else AppColors.Text
    Column(
        modifier = Modifier
            .width(76.dp)
            .clip(RoundedCornerShape(34.dp))
            .background(if (selected) selectedSoft else Color.Transparent)
            .clickable(onClick = onClick)
            .padding(horizontal = 8.dp, vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(25.dp))
        Text(text, color = color, fontWeight = FontWeight.Bold, fontSize = 9.sp, maxLines = 1)
    }
}

@Composable
private fun NobetcimTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = androidx.compose.material3.lightColorScheme(
            primary = AppColors.Primary,
            background = AppColors.Background,
            surface = Color.White
        ),
        content = content
    )
}

private object AppColors {
    val Primary = Color(0xFFC41E3A)
    val PrimarySoft = Color(0xFFFCE5EA)
    val Notary = Color(0xFF00A6A6)
    val NotarySoft = Color(0xFFE0F7F7)
    val Background = Color(0xFFF7F7F8)
    val SegmentedBackground = Color(0xFFE9E9EB)
    val Text = Color(0xFF101014)
    val Muted = Color(0xFF8A8A91)
    val SecondaryText = Color(0xFF9A9AA0)
    val Border = Color(0xFFE6E6EA)
}

private object AppMetrics {
    val CardRadius = 16.dp
}

private fun JSONArray.mapPharmacies(): List<Pharmacy> = mapPlaces(defaultName = "Eczane")

private fun JSONArray.mapNotaries(): List<Pharmacy> = mapPlaces(defaultName = "Noter")

private fun JSONArray.mapPlaces(defaultName: String): List<Pharmacy> = mapObjects { item ->
    val location = item.optJSONObject("konum")
    val lat = item.optNullableDouble("lat") ?: item.optNullableDouble("latitude") ?: location?.optNullableDouble("lat")
    val lng = item.optNullableDouble("lng") ?: item.optNullableDouble("longitude") ?: location?.optNullableDouble("lng")
    val rawDistance = item.optNullableDouble("mesafe") ?: item.optNullableDouble("distanceKm")
    Pharmacy(
        id = item.optString("id").ifBlank {
            listOf(item.optString("ad"), item.optString("il"), item.optString("ilce"), item.optString("adres"))
                .joinToString("-")
                .slugifiedTurkish()
        },
        name = item.optString("ad", item.optString("name", defaultName)).titleCaseTurkish(),
        city = item.optString("il", item.optString("city")).titleCaseTurkish(),
        district = item.optString("ilce", item.optString("district")).titleCaseTurkish(),
        address = item.optString("adres", item.optString("address")).titleCaseTurkish(),
        phone = item.optString("telefon", item.optString("phone")).ifBlank { null },
        latitude = lat,
        longitude = lng,
        distanceKm = rawDistance?.let { if (it >= 100.0) it / 1000.0 else it }
    )
}

private fun buildLeafletMapHtml(places: List<MapPlace>): String {
    val coordinatePlaces = places.filter { it.place.latitude != null && it.place.longitude != null }
    val markerData = coordinatePlaces.mapIndexed { index, item ->
        val place = item.place
        val color = if (item.isNotary) "#00A6A6" else "#C41E3A"
        """
          {
            index: $index,
            lat: ${place.latitude ?: 41.0082},
            lng: ${place.longitude ?: 28.9784},
            name: "${place.shortMapName().jsEscaped()}",
            fullName: "${place.name.jsEscaped()}",
            color: "$color"
          }
        """.trimIndent()
    }.joinToString(",")
    return """
        <!doctype html>
        <html lang="tr">
        <head>
          <meta charset="utf-8"/>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"/>
          <style>
            html, body { height: 100%; margin: 0; padding: 0; overflow: hidden; background: #dcebed; touch-action: none; user-select: none; }
            #map { position: relative; width: 100vw; height: 100vh; overflow: hidden; background: #dcebed; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
            .tile {
              position: absolute;
              width: 256px;
              height: 256px;
              will-change: transform;
              user-select: none;
              -webkit-user-drag: none;
            }
            .place {
              position: absolute;
              transform: translate(-50%, -26px);
              display: flex;
              flex-direction: column;
              align-items: center;
              gap: 3px;
              z-index: 20;
              cursor: pointer;
            }
            .dot {
              width: 27px;
              height: 27px;
              border-radius: 50%;
              border: 3px solid #fff;
              box-shadow: 0 4px 12px rgba(16,16,20,.26);
              box-sizing: border-box;
            }
            .label {
              max-width: 82px;
              overflow: hidden;
              white-space: nowrap;
              text-overflow: ellipsis;
              border-radius: 9px;
              padding: 3px 6px;
              background: #fff;
              color: #16171d;
              font-size: 10px;
              line-height: 1.05;
              font-weight: 800;
              box-shadow: 0 3px 10px rgba(16,16,20,.16);
            }
          </style>
        </head>
        <body>
          <div id="map"></div>
          <script>
            const places = [$markerData];
            const map = document.getElementById('map');
            let zoom = 13;
            let centerX = 0;
            let centerY = 0;
            let lastTapAt = 0;
            let activeTouches = new Map();
            let dragStart = null;
            let pinchStart = null;

            function worldSize(z) { return 256 * Math.pow(2, z); }
            function lngToX(lng, z) { return ((lng + 180) / 360) * worldSize(z); }
            function latToY(lat, z) {
              const sin = Math.sin(lat * Math.PI / 180);
              return (0.5 - Math.log((1 + sin) / (1 - sin)) / (4 * Math.PI)) * worldSize(z);
            }
            function clamp(v, min, max) { return Math.max(min, Math.min(max, v)); }

            function fitInitial() {
              const w = map.clientWidth || window.innerWidth;
              const h = map.clientHeight || window.innerHeight;
              if (!places.length) {
                zoom = 12;
                centerX = lngToX(28.9784, zoom);
                centerY = latToY(41.0082, zoom);
                return;
              }
              for (let z = 15; z >= 10; z--) {
                const xs = places.map(p => lngToX(p.lng, z));
                const ys = places.map(p => latToY(p.lat, z));
                const spanX = Math.max(...xs) - Math.min(...xs);
                const spanY = Math.max(...ys) - Math.min(...ys);
                if (spanX <= w * 0.72 && spanY <= h * 0.58) {
                  zoom = z;
                  centerX = (Math.min(...xs) + Math.max(...xs)) / 2;
                  centerY = (Math.min(...ys) + Math.max(...ys)) / 2;
                  return;
                }
              }
              zoom = 10;
              const xs = places.map(p => lngToX(p.lng, zoom));
              const ys = places.map(p => latToY(p.lat, zoom));
              centerX = (Math.min(...xs) + Math.max(...xs)) / 2;
              centerY = (Math.min(...ys) + Math.max(...ys)) / 2;
            }

            function render() {
              const w = map.clientWidth || window.innerWidth;
              const h = map.clientHeight || window.innerHeight;
              const world = worldSize(zoom);
              centerX = ((centerX % world) + world) % world;
              centerY = clamp(centerY, 0, world);
              const minX = Math.floor((centerX - w / 2) / 256) - 1;
              const maxX = Math.ceil((centerX + w / 2) / 256) + 1;
              const minY = Math.floor((centerY - h / 2) / 256) - 1;
              const maxY = Math.ceil((centerY + h / 2) / 256) + 1;
              const count = Math.pow(2, zoom);
              let html = '';
              for (let ty = minY; ty <= maxY; ty++) {
                if (ty < 0 || ty >= count) continue;
                for (let tx = minX; tx <= maxX; tx++) {
                  const wrappedX = ((tx % count) + count) % count;
                  const left = Math.round(w / 2 + tx * 256 - centerX);
                  const top = Math.round(h / 2 + ty * 256 - centerY);
                  html += '<img class="tile" draggable="false" style="transform:translate(' + left + 'px,' + top + 'px)" src="https://tile.openstreetmap.org/' + zoom + '/' + wrappedX + '/' + ty + '.png">';
                }
              }
              places.forEach(p => {
                const left = Math.round(w / 2 + lngToX(p.lng, zoom) - centerX);
                const top = Math.round(h / 2 + latToY(p.lat, zoom) - centerY);
                html += '<div class="place" style="left:' + left + 'px;top:' + top + 'px" onclick="AndroidMap.select(' + p.index + ')" title="' + p.fullName + '">' +
                  '<div class="dot" style="background:' + p.color + '"></div>' +
                  '<div class="label">' + p.name + '</div>' +
                  '</div>';
              });
              map.innerHTML = html;
            }

            function zoomAt(nextZoom, clientX, clientY) {
              nextZoom = clamp(nextZoom, 10, 17);
              if (nextZoom === zoom) return;
              const w = map.clientWidth || window.innerWidth;
              const h = map.clientHeight || window.innerHeight;
              const beforeX = centerX + clientX - w / 2;
              const beforeY = centerY + clientY - h / 2;
              const scale = Math.pow(2, nextZoom - zoom);
              centerX = beforeX * scale - clientX + w / 2;
              centerY = beforeY * scale - clientY + h / 2;
              zoom = nextZoom;
              render();
            }

            map.addEventListener('wheel', e => {
              e.preventDefault();
              zoomAt(zoom + (e.deltaY < 0 ? 1 : -1), e.clientX, e.clientY);
            }, { passive: false });

            map.addEventListener('touchstart', e => {
              e.preventDefault();
              activeTouches.clear();
              Array.from(e.touches).forEach(t => activeTouches.set(t.identifier, { x: t.clientX, y: t.clientY }));
              if (e.touches.length === 1) {
                const t = e.touches[0];
                const now = Date.now();
                if (now - lastTapAt < 280) zoomAt(zoom + 1, t.clientX, t.clientY);
                lastTapAt = now;
                dragStart = { x: t.clientX, y: t.clientY, cx: centerX, cy: centerY };
                pinchStart = null;
              } else if (e.touches.length === 2) {
                const a = e.touches[0], b = e.touches[1];
                pinchStart = {
                  dist: Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY),
                  zoom,
                  cx: centerX,
                  cy: centerY,
                  midX: (a.clientX + b.clientX) / 2,
                  midY: (a.clientY + b.clientY) / 2
                };
                dragStart = null;
              }
            }, { passive: false });

            map.addEventListener('touchmove', e => {
              e.preventDefault();
              if (e.touches.length === 1 && dragStart) {
                const t = e.touches[0];
                centerX = dragStart.cx - (t.clientX - dragStart.x);
                centerY = dragStart.cy - (t.clientY - dragStart.y);
                render();
              } else if (e.touches.length === 2 && pinchStart) {
                const a = e.touches[0], b = e.touches[1];
                const dist = Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY);
                const delta = Math.log2(dist / pinchStart.dist);
                const next = clamp(Math.round(pinchStart.zoom + delta), 10, 17);
                zoomAt(next, pinchStart.midX, pinchStart.midY);
              }
            }, { passive: false });

            map.addEventListener('touchend', e => {
              if (e.touches.length === 0) {
                dragStart = null;
                pinchStart = null;
              }
            });

            window.addEventListener('resize', render);
            fitInitial();
            render();
          </script>
        </body>
        </html>
    """.trimIndent()
}

private fun longitudeToWorldPixel(longitude: Double, zoom: Int): Double =
    ((longitude + 180.0) / 360.0) * 256.0 * 2.0.pow(zoom)

private fun latitudeToWorldPixel(latitude: Double, zoom: Int): Double {
    val sinLatitude = kotlin.math.sin(latitude * PI / 180.0)
    return (0.5 - ln((1 + sinLatitude) / (1 - sinLatitude)) / (4 * PI)) * 256.0 * 2.0.pow(zoom)
}

private fun chooseMapZoom(places: List<MapPlace>, widthPx: Double, heightPx: Double): Int {
    if (places.size <= 1 || widthPx <= 0.0 || heightPx <= 0.0) return 14
    return (15 downTo 10).firstOrNull { zoom ->
        val xs = places.mapNotNull { it.place.longitude?.let { lng -> longitudeToWorldPixel(lng, zoom) } }
        val ys = places.mapNotNull { it.place.latitude?.let { lat -> latitudeToWorldPixel(lat, zoom) } }
        val spanX = (xs.maxOrNull() ?: 0.0) - (xs.minOrNull() ?: 0.0)
        val spanY = (ys.maxOrNull() ?: 0.0) - (ys.minOrNull() ?: 0.0)
        spanX <= widthPx * 0.68 && spanY <= heightPx * 0.56
    } ?: 10
}

private fun mapCenterWorld(places: List<MapPlace>, zoom: Int): Pair<Double, Double> {
    val xs = places.mapNotNull { it.place.longitude?.let { lng -> longitudeToWorldPixel(lng, zoom) } }
    val ys = places.mapNotNull { it.place.latitude?.let { lat -> latitudeToWorldPixel(lat, zoom) } }
    if (xs.isEmpty() || ys.isEmpty()) {
        return longitudeToWorldPixel(28.9784, zoom) to latitudeToWorldPixel(41.0082, zoom)
    }
    return ((xs.minOrNull() ?: xs.first()) + (xs.maxOrNull() ?: xs.first())) / 2.0 to
        ((ys.minOrNull() ?: ys.first()) + (ys.maxOrNull() ?: ys.first())) / 2.0
}

private inline fun <T> JSONArray.mapObjects(transform: (JSONObject) -> T): List<T> =
    (0 until length()).mapNotNull { index -> optJSONObject(index)?.let(transform) }

private fun JSONObject.optNullableDouble(key: String): Double? =
    when (val value = opt(key)) {
        is Number -> value.toDouble()
        is String -> value.replace(",", ".").toDoubleOrNull()
        else -> null
    }

private fun List<Pharmacy>.sortedByDistance(origin: Location): List<Pharmacy> =
    map { pharmacy ->
        if (pharmacy.distanceKm != null || pharmacy.latitude == null || pharmacy.longitude == null) {
            pharmacy
        } else {
            val target = Location("pharmacy").apply {
                latitude = pharmacy.latitude
                longitude = pharmacy.longitude
            }
            pharmacy.copy(distanceKm = origin.distanceTo(target) / 1000.0)
        }
    }.sortedBy { it.distanceKm ?: Double.MAX_VALUE }

private fun List<Pharmacy>.sortedByDistance(latitude: Double, longitude: Double): List<Pharmacy> =
    sortedByDistance(Location("origin").apply {
        this.latitude = latitude
        this.longitude = longitude
    })

private fun Double.cacheCoordinate(): String =
    String.format(Locale.US, "%.2f", this)

private fun locationPermissionsGranted(context: Context): Boolean =
    ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

private fun Context.lastKnownLocation(): Location? {
    if (!locationPermissionsGranted(this)) return null
    val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
    return listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
        .mapNotNull { provider -> runCatching { manager.getLastKnownLocation(provider) }.getOrNull() }
        .maxByOrNull { it.time }
}

private fun Context.bestKnownLocation(): Location? =
    lastKnownLocation() ?: if (locationPermissionsGranted(this)) {
        Location("kadikoy-fallback").apply {
            latitude = 40.9909
            longitude = 29.0303
        }
    } else {
        null
    }

private fun Context.requestFreshLocation(onLocation: (Location) -> Unit) {
    if (!locationPermissionsGranted(this)) return
    val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
    val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
        .filter { provider -> runCatching { manager.isProviderEnabled(provider) }.getOrDefault(false) }
    if (providers.isEmpty()) return

    lateinit var listener: LocationListener
    listener = LocationListener { freshLocation ->
        onLocation(freshLocation)
        runCatching { manager.removeUpdates(listener) }
    }
    providers.forEach { provider ->
        runCatching { manager.requestSingleUpdate(provider, listener, Looper.getMainLooper()) }
    }
}

private fun Context.callPhone(phone: String?) {
    val cleaned = phone?.filter { it.isDigit() || it == '+' }.orEmpty()
    if (cleaned.isBlank()) return
    startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:$cleaned")))
}

private fun Context.openDirections(pharmacy: Pharmacy) {
    val latitude = pharmacy.latitude
    val longitude = pharmacy.longitude
    val uri = if (latitude != null && longitude != null) {
        Uri.parse("geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encode(pharmacy.name)})")
    } else {
        Uri.parse("geo:0,0?q=${Uri.encode("${pharmacy.name} ${pharmacy.address}")}")
    }
    startActivity(Intent(Intent.ACTION_VIEW, uri))
}

private fun Int.toUserMessage(): String = when (this) {
    400 -> "Arama bilgileri geçersiz."
    401, 403 -> "API yetkilendirmesi başarısız."
    404 -> "Bu bölgede sonuç bulunamadı."
    429 -> "Sunucu geçici olarak yoğun. Lütfen kısa süre sonra tekrar deneyin."
    503 -> "API şu anda yapılandırılmamış."
    in 500..599 -> "Eczane bilgileri alınamadı."
    else -> "Beklenmeyen bir hata oluştu."
}

private fun Throwable.toUserMessage(fallback: String): String = when (this) {
    is UnknownHostException -> "İnternet bağlantısı veya DNS çözümlenemedi. Emülatörün internet bağlantısını kontrol edin."
    is SocketTimeoutException -> "Sunucuya bağlanma süresi doldu. Lütfen tekrar deneyin."
    is IllegalStateException -> message?.takeIf { it.isNotBlank() } ?: fallback
    else -> message?.takeIf { it.isNotBlank() } ?: fallback
}

private fun String.encodeUrl(): String = URLEncoder.encode(this, Charsets.UTF_8.name())

private fun Pharmacy.shortMapName(): String =
    name
        .replace(" Eczanesi", "", ignoreCase = true)
        .replace(" Noterliği", "", ignoreCase = true)
        .split(" ")
        .take(2)
        .joinToString(" ")
        .ifBlank { name }

private fun List<MapPlace>.forMapDisplay(): List<MapPlace> =
    sortedWith(
        compareBy<MapPlace> { it.place.distanceKm ?: Double.MAX_VALUE }
            .thenBy(turkishComparator()) { it.place.name }
    )

private fun <T> turkishComparator(selector: (T) -> String = { it.toString() }): Comparator<T> {
    val collator = Collator.getInstance(Locale("tr", "TR")).apply {
        strength = Collator.PRIMARY
    }
    return Comparator { left, right -> collator.compare(selector(left), selector(right)) }
}

private fun geoDistanceKm(lat1: Double, lng1: Double, lat2: Double, lng2: Double): Double {
    val dLat = (lat2 - lat1) * PI / 180.0
    val dLng = (lng2 - lng1) * PI / 180.0
    val a = kotlin.math.sin(dLat / 2.0).pow(2.0) +
        kotlin.math.cos(lat1 * PI / 180.0) *
        kotlin.math.cos(lat2 * PI / 180.0) *
        kotlin.math.sin(dLng / 2.0).pow(2.0)
    return 12742.0 * kotlin.math.atan2(kotlin.math.sqrt(a), kotlin.math.sqrt(1.0 - a))
}

private fun String.slugifiedTurkish(): String =
    lowercase(Locale("tr", "TR"))
        .replace("ı", "i")
        .replace("ğ", "g")
        .replace("ü", "u")
        .replace("ş", "s")
        .replace("ö", "o")
        .replace("ç", "c")
        .replace(Regex("[^a-z0-9]+"), "-")
        .trim('-')

private fun String.titleCaseTurkish(): String =
    lowercase(Locale("tr", "TR"))
        .split(Regex("\\s+"))
        .joinToString(" ") { word ->
            word.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale("tr", "TR")) else it.toString() }
        }
        .trim()

private fun String.jsEscaped(): String =
    replace("\\", "\\\\")
        .replace("\"", "\\\"")
        .replace("\n", " ")
        .replace("\r", " ")

private fun String.htmlEscaped(): String =
    replace("&", "&amp;")
        .replace("\"", "&quot;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")

private fun String.matchesTurkish(other: String): Boolean = slugifiedTurkish() == other.slugifiedTurkish()

private val fallbackCities = listOf(
    CityInfo("İstanbul", "istanbul"),
    CityInfo("Ankara", "ankara"),
    CityInfo("İzmir", "izmir")
)

private val fallbackDistricts = mapOf(
    "istanbul" to listOf("Kadıköy", "Üsküdar", "Beşiktaş", "Fatih", "Şişli").map { DistrictInfo(it, it.slugifiedTurkish()) },
    "ankara" to listOf("Çankaya", "Keçiören", "Mamak", "Yenimahalle").map { DistrictInfo(it, it.slugifiedTurkish()) },
    "izmir" to listOf("Bornova", "Buca", "Karşıyaka", "Konak").map { DistrictInfo(it, it.slugifiedTurkish()) }
)
