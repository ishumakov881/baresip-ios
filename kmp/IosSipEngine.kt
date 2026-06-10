package net.lds.sip

import kotlin.concurrent.Volatile
import kotlin.coroutines.CoroutineContext
import kotlinx.cinterop.CPointer
import kotlinx.cinterop.StableRef
import kotlinx.cinterop.staticCFunction
import kotlinx.cinterop.toKString
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.newSingleThreadContext
import platform.Foundation.NSTemporaryDirectory

/**
 * iOS SIP engine — cinterop на [LdsTelephonyKit.xcframework].
 * Скопировать в :kmp:sip iosMain после подключения prebuilt.
 */
class IosSipEngine : SipEngine {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val _events = MutableSharedFlow<SipEngineEvent>(extraBufferCapacity = 32)
    override val events: SharedFlow<SipEngineEvent> = _events.asSharedFlow()

    @Volatile
    private var loopContext: CoroutineContext? = null

    private val eventSinkRef = StableRef.create(EventSink(_events))

    init {
        telephony_set_event_handler(staticCFunction(::onTelephonyEvent), eventSinkRef.asCPointer())
    }

    override suspend fun start() {
        if (loopContext != null) return
        val ctx = newSingleThreadContext("lds-telephony")
        loopContext = ctx
        scope.launch(ctx) {
            val ok = telephony_init(NSTemporaryDirectory()) == 0
            _events.emit(SipEngineEvent.InitResult(success = ok))
            if (ok) telephony_mainLoop()
            _events.emit(SipEngineEvent.CallClosed(statusCode = 0))
        }
    }

    override fun shutdown() {
        telephony_cmd(CMD_STOP.toInt(), null)
        loopContext = null
    }

    override fun placeCall(params: SipCallParams) {
        val ac = allocAudioCall(params) ?: return
        telephony_cmd(CMD_AUDIO_CALL.toInt(), ac)
    }

    override fun hangup() {
        telephony_cmd(CMD_HANGUP.toInt(), null)
    }

    override fun stopService() {
        shutdown()
    }

    private class EventSink(
        private val events: MutableSharedFlow<SipEngineEvent>,
    ) {
        fun emit(event: Int, scode: Int, callId: String?) {
            when (event) {
                UA_EVENT_REGISTER_FAIL ->
                    events.tryEmit(SipEngineEvent.InitResult(success = false))
                UA_EVENT_CALL_RINGING ->
                    events.tryEmit(SipEngineEvent.CallRinging(callId))
                UA_EVENT_CALL_ESTABLISHED ->
                    events.tryEmit(SipEngineEvent.CallEstablished)
                UA_EVENT_CALL_CLOSED ->
                    events.tryEmit(SipEngineEvent.CallClosed(scode))
            }
        }
    }

    companion object {
        private const val UA_EVENT_REGISTER_FAIL = 2
        private const val UA_EVENT_CALL_RINGING = 10
        private const val UA_EVENT_CALL_ESTABLISHED = 12
        private const val UA_EVENT_CALL_CLOSED = 13
        private const val CMD_AUDIO_CALL = 101
        private const val CMD_HANGUP = 102
        private const val CMD_STOP = 103
    }
}

private fun onTelephonyEvent(
    event: Int,
    scode: Int,
    callId: CPointer<ByteVar>?,
    userdata: COpaquePointer?,
) {
    val sink = userdata?.asStableRef<IosSipEngine.EventSink>()?.get() ?: return
    sink.emit(event, scode, callId?.toKString())
}

// TODO: allocAudioCall — malloc AudioCall_t + strdup fields (cinterop struct)
