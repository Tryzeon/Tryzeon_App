package com.lib.chottu_link

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import androidx.core.net.toUri
import com.chottulink.lib.ChottuLink
import com.chottulink.lib.ChottuLink.OnFailureListener
import com.chottulink.lib.ChottuLink.OnSuccessListener
import com.chottulink.lib.DynamicLink
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry

class ChottuLinkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler, PluginRegistry.NewIntentListener {
    private lateinit var methodChannel : MethodChannel
    private lateinit var applicationContext: Context
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private fun toStringAnyMap(input: Any?): Map<String, Any?>? {
        val m = input as? Map<*, *> ?: return null
        val out = mutableMapOf<String, Any?>()
        for (entry in m.entries) {
            out[entry.key?.toString() ?: ""] = entry.value
        }
        return out
    }

    companion object {
        private const val METHOD_CHANNEL_NAME = "chottu_link"
        private const val EVENT_CHANNEL_NAME = "chottu_link/events"

        // LOCAL FORK PATCH: hosts ChottuLink is allowed to claim. Add a custom
        // ChottuLink domain here if you use one.
        private val CHOTTU_HOST_SUFFIXES = listOf("chottu.link")
    }

    /// LOCAL FORK PATCH: true only for ChottuLink-owned App Links. Lets the app's
    /// own tryzeon.com App Links fall through to Flutter -> go_router.
    private fun isChottuLinkIntent(intent: Intent?): Boolean {
        val host = intent?.data?.host?.lowercase() ?: return false
        return CHOTTU_HOST_SUFFIXES.any { host == it || host.endsWith(".$it") }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel?.setStreamHandler(this)
        
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        activity?.intent?.let {
            processIntentForDeepLink(it, "onListenInitial")
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun processIntentForDeepLink(intent: Intent?, source: String) {
        if (intent == null) {
            return
        }
        try {
            ChottuLink.getAppLinkData(intent)
                .addOnSuccessListener(OnSuccessListener<ChottuLink.AppLinkData> { appLinkData ->
                    if (appLinkData?.link != null) {
                        val deepLink = appLinkData.link.toString()


                        val deepLinkData = mapOf(
                            "link" to deepLink,
                            "shortLink" to appLinkData.shortLink.toString(),
                            "shortLinkRaw" to appLinkData.shortLinkRaw.toString(),
                            "isDeferred" to appLinkData.isDeferred
                        )
                        eventSink?.success(deepLinkData)
                    } else {
                    }
                })
                .addOnFailureListener(OnFailureListener { e ->
                })
        } catch (e: Exception) {
        }
    }
    
    override fun onNewIntent(intent: Intent): Boolean {
        // LOCAL FORK PATCH: warm-start App Links to the app's own domain
        // (tryzeon.com) must reach Flutter -> go_router, so only consume
        // ChottuLink-owned intents here. Cold-start launch-intent processing
        // (onAttachedToActivity/onListen) is left untouched so deferred deep
        // linking via Install Referrer keeps working.
        if (!isChottuLinkIntent(intent)) return false
        processIntentForDeepLink(intent, "onNewIntent")
        return true
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "init" -> {
                val apiKey = call.arguments as? String
                if (apiKey.isNullOrEmpty()) {
                    result.error("INVALID_APIKEY", "ApiKey Required", null)
                    return
                }
                try {
                    ChottuLink.init(applicationContext, apiKey)
                    result.success("SDK init call dispatched.")
                } catch (e: Exception) {
                    result.error("INIT_FAILED", "Native ChottuLink.init threw an exception: ${e.message}", e.toString())
                }
            }
            "createDynamicLink" -> {
                val args = call.arguments as? Map<String, Any?>
                if (args == null) {
                    result.error("CL-1", "Arguments map is null for createDynamicLink", null)
                    return
                }

                try {
                    val destinationUrlString = args["link"] as? String
                    val domainString = args["domain"] as? String
                    val androidBehaviorParam = args["androidBehaviour"] as? Int ?: DynamicLink.BEHAVIOR_APP
                    val iosBehaviorParam = args["iosBehaviour"] as? Int ?: DynamicLink.BEHAVIOR_APP
                    val utmSource = args["utmSource"] as? String
                    val utmMedium = args["utmMedium"] as? String
                    val utmCampaign = args["utmCampaign"] as? String
                    val utmContent = args["utmContent"] as? String
                    val utmTerm = args["utmTerm"] as? String
                    val linkName = args["linkName"] as? String
                    val selectedPath = args["selectedPath"] as? String
                    val socialDescription = args["socialDescription"] as? String
                    val socialImageUrl = args["socialImageUrl"] as? String
                    val socialTitle = args["socialTitle"] as? String

                    val linkUri = destinationUrlString?.toUri()

                    val dynamicLinkBuilder = ChottuLink.createDynamicLink()
                        .setLink(linkUri)
                        .setDomain(domainString)
                        .androidBehavior(androidBehaviorParam)
                        .iosBehavior(iosBehaviorParam)

                    utmSource?.takeIf { it.isNotEmpty() }?.let { dynamicLinkBuilder.setUtmSource(it) }
                    utmMedium?.takeIf { it.isNotEmpty() }?.let { dynamicLinkBuilder.setUtmMedium(it) }
                    utmCampaign?.takeIf { it.isNotEmpty() }?.let { dynamicLinkBuilder.setUtmCampaign(it) }
                    utmTerm?.takeIf { it.isNotEmpty() }?.let { dynamicLinkBuilder.setUtmTerm(it) }
                    utmContent?.takeIf { it.isNotEmpty() }?.let { dynamicLinkBuilder.setUtmContent(it) }

                    linkName?.takeIf { it.isNotEmpty() }?.let { dynamicLinkBuilder.setLinkName(it) }
                    selectedPath?.takeIf { it.isNotEmpty() }?.let { dynamicLinkBuilder.setSelectedPath(it) }
                    socialDescription?.takeIf { it.isNotEmpty() }?.let { dynamicLinkBuilder.setSocialDescription(it) }
                    socialImageUrl?.takeIf { it.isNotEmpty() }?.let { dynamicLinkBuilder.setSocialImageUrl(it) }
                    socialTitle?.takeIf { it.isNotEmpty() }?.let { dynamicLinkBuilder.setSocialTitle(it) }

                    dynamicLinkBuilder.build()
                        .addOnSuccessListener(OnSuccessListener { dynamicLink: DynamicLink? ->
                            if (dynamicLink != null && dynamicLink.uri != null) {
                                val shortUrl = dynamicLink.uri.toString()
                                result.success(shortUrl)
                            } else {
                                result.error("UNKNOWN", "Dynamic link creation succeeded but result was null or had no URI.", null)
                            }
                        })
                        .addOnFailureListener(OnFailureListener { e: Exception? ->
                            result.error("CL-2", "Failed to create dynamic link: ${e?.message}", null)
                        })

                } catch (e: ClassCastException) {
                    result.error("CL-3", "Invalid argument types for createDynamicLink: ${e.message}", null)
                } catch (e: IllegalArgumentException) {
                    result.error("CL-4", "destination_url ('link') is not a valid URI: ${e.message}", null)
                } catch (e: Exception) {
                    result.error("CL-5", "General error during createDynamicLink: ${e.message}", e.toString())
                }
            }
            "getAppLinkData" -> {
                val currentActivity = activity
                if (currentActivity == null) {
                    result.error("NO_ACTIVITY", "Activity is not available.", null)
                    return
                }
                processIntentForDeepLink(currentActivity.intent, "getAppLinkDataMethod")
                result.success("Attempted to process current intent for app link data. Listen to EventChannel ('${EVENT_CHANNEL_NAME}') for link results.")
            }
            "getAppLinkDataFromUrl" -> {
                val shortLink = call.arguments as? String
                if (shortLink == null) {
                    result.error("RL-1", "ShortLink is null for resolveDynamicLink", null)
                    return
                }

                try {
                    ChottuLink.getAppLinkDataFromUri(shortLink.toUri())
                        .addOnSuccessListener { data ->

                            if (data == null || data.link == null || data.link.toString() == ""){
                                result.error("RL-2", "Error during resolve dynamic link: ","No Link found !!")
                                return@addOnSuccessListener
                            }

                            val myMutableMap = mutableMapOf<String, Any>()
                            myMutableMap["link"] = data.link.toString()
                            myMutableMap["shortLink"] = data.shortLink.toString()
                            myMutableMap["shortLinkRaw"] = data.shortLinkRaw.toString()
                            myMutableMap["isDeferred"] = data.isDeferred
                            result.success(myMutableMap)
                        }
                        .addOnFailureListener { error ->
                            result.error("RL-3", "Error during resolve dynamic link: ${error.message}", error.toString())
                        }
                }catch (e: Exception){
                    result.error("RL-4", "Error during resolve dynamic link: ${e.message}", e.toString())
                }
            }

            // =======================
            // Android-only parity APIs
            // =======================

            "getApiKey" -> {
                result.success(ChottuLink.getApiKey())
            }

            "getAttributionData" -> {
                val data = ChottuLink.getAttributionData()
                if (data == null) {
                    result.success(null)
                    return
                }

                val myMutableMap = mutableMapOf<String, Any?>()
                myMutableMap["attributionType"] = data.attributionType
                myMutableMap["installId"] = data.installId
                myMutableMap["matchFound"] = data.isMatchFound
                myMutableMap["matchType"] = data.matchType
                myMutableMap["shortUrl"] = data.shortUrl
                myMutableMap["clickedShortUrl"] = data.clickedShortUrl
                myMutableMap["destinationUrl"] = data.destinationUrl
                myMutableMap["destinationWithUtm"] = data.destinationWithUtm
                myMutableMap["utmSource"] = data.utmSource
                myMutableMap["utmMedium"] = data.utmMedium
                myMutableMap["utmCampaign"] = data.utmCampaign
                myMutableMap["utmTerm"] = data.utmTerm
                myMutableMap["utmContent"] = data.utmContent
                myMutableMap["isAttributed"] = data.isAttributed

                result.success(myMutableMap)
            }

            "identify" -> {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("ID-1", "identify args map is null", null)
                    return
                }

                val builder = ChottuLink.CustomerMeta.Builder()
                (args["id"] as? String)?.let { builder.setId(it) }
                (args["name"] as? String)?.let { builder.setName(it) }
                (args["email"] as? String)?.let { builder.setEmail(it) }
                (args["phone"] as? String)?.let { builder.setPhone(it) }
                (args["emailSha256"] as? String)?.let { builder.setEmailSha256(it) }
                (args["phoneSha256"] as? String)?.let { builder.setPhoneSha256(it) }

                ChottuLink.identify(builder.build())
                result.success(null)
            }

            "trackLead" -> {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("TL-1", "trackLead args map is null", null)
                    return
                }

                val builder = ChottuLink.LeadMeta.Builder()
                (args["eventName"] as? String)?.let { builder.setEventName(it) }
                val metadata = toStringAnyMap(args["metadata"])
                if (metadata != null) {
                    @Suppress("UNCHECKED_CAST")
                    builder.setMetadata(metadata as Map<String, Any>)
                }

                ChottuLink.trackLead(builder.build())
                result.success(null)
            }

            "trackConversion" -> {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("TC-1", "trackConversion args map is null", null)
                    return
                }

                val builder = ChottuLink.ConversionMeta.Builder()

                val revenueAny = args["revenue"]
                val revenue = (revenueAny as? Number)?.toDouble()
                if (revenue == null) {
                    result.error("TC-2", "revenue is missing or not a number", null)
                    return
                }
                builder.setRevenue(revenue)

                (args["currency"] as? String)?.let { builder.setCurrency(it) }
                (args["eventName"] as? String)?.let { builder.setEventName(it) }
                (args["productId"] as? String)?.let { builder.setProductId(it) }
                (args["transactionId"] as? String)?.let { builder.setTransactionId(it) }

                val metadata = toStringAnyMap(args["metadata"])
                if (metadata != null) {
                    @Suppress("UNCHECKED_CAST")
                    builder.setMetadata(metadata as Map<String, Any>)
                }

                ChottuLink.trackConversion(builder.build())
                result.success(null)
            }

            "trackEvent" -> {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("TE-1", "trackEvent args map is null", null)
                    return
                }

                val eventName = args["eventName"] as? String ?: ""
                val eventData = toStringAnyMap(args["eventData"])

                @Suppress("UNCHECKED_CAST")
                ChottuLink.trackEvent(eventName, eventData as? Map<String, Any>)
                result.success(null)
            }

            "flush" -> {
                ChottuLink.flush()
                result.success(null)
            }

            "logout" -> {
                ChottuLink.logout()
                result.success(null)
            }

            "optOut" -> {
                val optOut = call.arguments as? Boolean ?: false
                ChottuLink.optOut(optOut)
                result.success(null)
            }

            "isOptedOut" -> {
                result.success(ChottuLink.isOptedOut())
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        eventChannel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addOnNewIntentListener(this)
        activity?.intent?.let {
            processIntentForDeepLink(it, "onAttachedToActivity")
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addOnNewIntentListener(this)
        activity?.intent?.let {
            processIntentForDeepLink(it, "onReattachedToActivity")
        }
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
        activity = null
    }
}
