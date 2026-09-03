package com.invisiblewrench.fluttermidicommand

import android.content.pm.ServiceInfo
import android.media.midi.*
import com.invisiblewrench.fluttermidicommand.pigeon.MidiDeviceType
import com.invisiblewrench.fluttermidicommand.pigeon.MidiHostDevice
import com.invisiblewrench.fluttermidicommand.pigeon.MidiPacket
import com.invisiblewrench.fluttermidicommand.pigeon.MidiSetupChange

class ConnectedDevice(
    device: MidiDevice,
    private val logicalDeviceId: String,
    private val inputPortIndex: Int?,
    private val outputPortIndex: Int?,
    private val onSetupChanged: (MidiSetupChange) -> Unit,
    private val onDataReceived: (MidiPacket) -> Unit,
    private val onConnectionChanged: (String, Boolean) -> Unit,
    private val deviceType: MidiDeviceType,
) : Device(logicalDeviceId, device.info.type.toString()) {
    var inputPort: MidiInputPort? = null
    var outputPort: MidiOutputPort? = null

    private var isOwnVirtualDevice = false
    private var isClosed = false

    init {
        this.midiDevice = device
    }

    override fun connect() {
        this.midiDevice.info.let {
            val serviceInfo = it.properties.getParcelable<ServiceInfo>("service_info")
            if (serviceInfo?.name == "com.invisiblewrench.fluttermidicommand.VirtualDeviceService") {
                isOwnVirtualDevice = true
                this.receiver = RXReceiver(_toHostDevice(MidiDeviceType.OWN_VIRTUAL), onDataReceived)
            } else {
                this.receiver = RXReceiver(_toHostDevice(deviceType), onDataReceived)
                inputPortIndex?.let { portIndex ->
                    this.inputPort = this.midiDevice.openInputPort(portIndex)
                }
            }
            outputPortIndex?.let { portIndex ->
                this.outputPort = this.midiDevice.openOutputPort(portIndex)
                this.outputPort?.connect(this.receiver)
            }
        }
        onSetupChanged(MidiSetupChange.DEVICE_CONNECTED)
        onConnectionChanged(id, true)
    }

    private fun _toHostDevice(type: MidiDeviceType): MidiHostDevice {
        return MidiHostDevice(
            id = logicalDeviceId,
            name = this.midiDevice.info.properties.getString(MidiDeviceInfo.PROPERTY_NAME),
            type = type,
            connected = true,
            inputs = null,
            outputs = null,
        )
    }

    override fun send(data: ByteArray, timestamp: Long?) {
        if(isOwnVirtualDevice) {
            if (timestamp == null)
                this.receiver?.send(data, 0, data.size)
            else
                this.receiver?.send(data, 0, data.size, timestamp)

        } else {
            this.inputPort?.send(data, 0, data.count(), if (timestamp is Long) timestamp else 0)
        }
    }

    override fun close() {
        // Android can request cleanup twice when the user physically unplugs
        // a USB MIDI device. Only run the native cleanup once.
        if (isClosed) {
            return
        }
        isClosed = true

        // A removed USB device can throw IOException: EPIPE while a port is
        // being flushed or closed. Clean up every resource independently so
        // one unavailable port cannot terminate the Android app process.
        closeSafely("input port flush") { this.inputPort?.flush() }
        closeSafely("input port") { this.inputPort?.close() }
        closeSafely("output port receiver") {
            this.outputPort?.disconnect(this.receiver)
        }
        closeSafely("output port") { this.outputPort?.close() }
        this.inputPort = null
        this.outputPort = null
        this.receiver = null
        closeSafely("MIDI device") { this.midiDevice.close() }

        onSetupChanged(MidiSetupChange.DEVICE_DISCONNECTED)
        onConnectionChanged(id, false)
    }

    private inline fun closeSafely(resourceName: String, closeAction: () -> Unit) {
        try {
            closeAction()
        } catch (exception: Exception) {
            MidiLogger.debug("Ignored $resourceName cleanup error: $exception")
        }
    }

    class RXReceiver(
        private val deviceInfo: MidiHostDevice,
        private val onDataReceived: (MidiPacket) -> Unit,
    ) : MidiReceiver() {
        private val parser = MidiPacketParser { bytes, timestamp ->
            onDataReceived(
                MidiPacket(
                    device = deviceInfo,
                    data = bytes,
                    timestamp = timestamp,
                ),
            )
        }

        override fun onSend(msg: ByteArray?, offset: Int, count: Int, timestamp: Long) {
            msg?.also { parser.parse(it, offset, count, timestamp) }
        }
    }

}
