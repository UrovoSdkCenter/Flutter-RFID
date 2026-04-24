package com.urovo.rfid;

import android.app.Activity;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import com.ubx.usdk.RFIDSDKManager;
import com.ubx.usdk.bean.ReadTag;
import com.ubx.usdk.bean.Tag6C;
import com.ubx.usdk.bean.TagResult;
import com.ubx.usdk.bean.CustomRegionBean;
import com.ubx.usdk.bean.MatchData;
import com.ubx.usdk.bean.enums.CountryCode;
import com.ubx.usdk.bean.enums.FrequencyRegion;
import com.ubx.usdk.bean.enums.InventorySceneMode;
import com.ubx.usdk.bean.enums.ModuleType;
import com.ubx.usdk.bean.enums.QueryMemBank;
import com.ubx.usdk.bean.enums.ReaderDeviceType;
import com.ubx.usdk.bean.enums.RfidProfile;
import com.ubx.usdk.io.GripDeviceManager;
import com.ubx.usdk.io.listener.BatteryGripListener;
import com.ubx.usdk.io.listener.KeyEventListener;
import com.ubx.usdk.io.scan.BarcodeCallback;
import com.ubx.usdk.listener.DataCallback;
import com.ubx.usdk.listener.FWUpdateCallback;
import com.ubx.usdk.listener.InitListener;
import com.ubx.usdk.rfid.update.FirmwareManager;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * Flutter RFID Plugin — 封装 URFIDLibrary v2.6+（RFIDSDKManager）。
 * 支持两种连接方式：
 * - 一体机/UART：initSdk()，内部调用 RFIDSDKManager.init(Context, InitListener)
 * - 蓝牙分体设备：initSdkBle(mac)，内部调用 RFIDSDKManager.initBTtoMac(...)
 * <p>
 * 事件通过单一 EventChannel "plugin_rfid_event" 推送，eventType 区分：
 * event_inventory_tag / event_inventory_tag_end / event_battery /
 * event_barcode / event_key / event_module_switch / event_fw_update
 */
public class RfidPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {

    // ── Channel 名称 ───────────────────────────────────────────────────────
    private static final String METHOD_CHANNEL = "rfid";
    private static final String EVENT_CHANNEL = "plugin_rfid_event";

    // ── Event 类型常量 ─────────────────────────────────────────────────────
    static final String EVENT_INVENTORY_TAG = "event_inventory_tag";
    static final String EVENT_INVENTORY_TAG_END = "event_inventory_tag_end";
    static final String EVENT_BATTERY = "event_battery";
    static final String EVENT_BARCODE = "event_barcode";
    static final String EVENT_KEY = "event_key";
    static final String EVENT_MODULE_SWITCH = "event_module_switch";
    static final String EVENT_FW_UPDATE = "event_fw_update";
    /** 链路连接状态：data 为 Map，含 {@code connected} (boolean)。每次 InitListener 回调都会推送，与 init 的 MethodChannel 结果无关。 */
    static final String EVENT_CONNECTION = "event_connection";

    // ── 错误哨兵 ───────────────────────────────────────────────────────────
    private static final int ERR_PARAM = -19;
    private static final int ERR_NO_INIT = -99;

    private static final String TAG = "RfidPlugin";

    // ── 状态 ───────────────────────────────────────────────────────────────
    private MethodChannel methodChannel;
    private EventChannel.EventSink eventSink;
    private Context appContext;
    private Activity activity;

    /**
     * 缓存支持列表，SDK init 后填充一次
     */
    private List<FrequencyRegion> frequencyBandList;
    private List<RfidProfile> profileList;

    // ── DataCallback ───────────────────────────────────────────────────────
    private final DataCallback dataCallback = new DataCallback() {
        @Override
        public void onInventoryTag(ReadTag readTag) {
            if (readTag == null) return;
            HashMap<String, Object> tag = new HashMap<>();
            tag.put("EPC", readTag.epcId != null ? readTag.epcId : "");
            tag.put("TID", readTag.memId != null ? readTag.memId : "");
            tag.put("RSSI", readTag.rssi);
            tag.put("BID", readTag.BID != null ? readTag.BID : "");
            sendEvent(buildEvent(EVENT_INVENTORY_TAG, tag));
        }

        @Override
        public void onInventoryTagEnd() {
            sendEvent(buildEvent(EVENT_INVENTORY_TAG_END, ""));
        }
    };

    // ── BatteryGripListener ────────────────────────────────────────────────
    private final BatteryGripListener batteryGripListener = new BatteryGripListener() {
        @Override
        public void isChange(int change) {
            HashMap<String, Object> data = new HashMap<>();
            data.put("isCharging", change);
            data.put("level", GripDeviceManager.getInstance().getElectricQuantity());
            sendEvent(buildEvent(EVENT_BATTERY, data));
        }

        @Override
        public void level(int percent) {
            HashMap<String, Object> data = new HashMap<>();
            data.put("isCharging", GripDeviceManager.getInstance().getIsChange());
            data.put("level", percent);
            sendEvent(buildEvent(EVENT_BATTERY, data));
        }
    };

    // ── BarcodeCallback ────────────────────────────────────────────────────
    private final BarcodeCallback barcodeCallback = new BarcodeCallback() {
        @Override
        public void onResult(byte[] bytes) {
            String barcode = bytes != null ? new String(bytes).trim() : "";
            MLog.d(TAG, ">> onBarcodeResult: " + barcode);
            sendEvent(buildEvent(EVENT_BARCODE, barcode));
        }
    };

    // ── KeyEventListener ───────────────────────────────────────────────────
    private final KeyEventListener keyEventListener = new KeyEventListener() {
        @Override
        public void event(int keyCode, boolean isDown) {
            MLog.d(TAG, ">> onKeyEvent keyCode=" + keyCode + " isDown=" + isDown);
            HashMap<String, Object> data = new HashMap<>();
            data.put("keyCode", keyCode);
            data.put("isDown", isDown);
            sendEvent(buildEvent(EVENT_KEY, data));
        }
    };

    // ── ModelInfoCallback / setSwitchCallback ─────────────────────────────
    // SDK 文档（v2.23）中未列出该接口，暂不注册。
    // 如后续 SDK 版本提供，可在此处添加实现并在 registerCallbacksAndCacheInfo 中注册。

    // ── FlutterPlugin ──────────────────────────────────────────────────────
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        appContext = binding.getApplicationContext();

        methodChannel = new MethodChannel(binding.getBinaryMessenger(), METHOD_CHANNEL);
        methodChannel.setMethodCallHandler(this);

        EventChannel eventChannel = new EventChannel(binding.getBinaryMessenger(), EVENT_CHANNEL);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                MLog.d(TAG, ">> EventChannel onListen");
                eventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                MLog.d(TAG, ">> EventChannel onCancel");
                eventSink = null;
            }
        });
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;
        eventSink = null;
    }

    // ── ActivityAware ──────────────────────────────────────────────────────
    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        releaseRfid();
        activity = null;
    }

    // ── MethodCallHandler ──────────────────────────────────────────────────
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        MLog.d(TAG, ">> onMethodCall: " + call.method + " args=" + call.arguments);
        switch (call.method) {
            // ── SDK 生命周期 ───────────────────────────────────────────────
            case "initSdk":
                initSdk(result);
                return;
            case "initSdkBle":
                initSdkBle(call, result);
                return;
            case "releaseSdk":
                releaseSdk(result);
                return;
            case "isConnected":
                isConnected(result);
                return;
            // ── 盘存 ──────────────────────────────────────────────────────
            case "startInventory":
                startInventory(call, result);
                return;
            case "stopInventory":
                stopInventory(result);
                return;
            case "inventorySingle":
                inventorySingle(result);
                return;
            // ── 标签操作 ──────────────────────────────────────────────────
            case "readTag":
                readTag(call, result);
                return;
            case "writeTag":
                writeTag(call, result);
                return;
            case "writeTagEpc":
                writeTagEpc(call, result);
                return;
            case "writeEpc":
                writeEpc(call, result);
                return;
            case "killTag":
                killTag(call, result);
                return;
            case "lockTag":
                lockTag(call, result);
                return;
            case "lightUpLedTag":
                lightUpLedTag(call, result);
                return;
            // ── TID 操作 ──────────────────────────────────────────────────
            case "readDataByTid":
                readDataByTid(call, result);
                return;
            case "writeTagByTid":
                writeTagByTid(call, result);
                return;
            case "lockByTID":
                lockByTID(call, result);
                return;
            case "killTagByTid":
                killTagByTid(call, result);
                return;
            case "writeTagEpcByTid":
                writeTagEpcByTid(call, result);
                return;
            // ── 带掩码操作 ────────────────────────────────────────────────
            case "maskReadTag":
                maskReadTag(call, result);
                return;
            case "maskWriteTag":
                maskWriteTag(call, result);
                return;
            // ── 大容量标签 ────────────────────────────────────────────────
            case "readTagExt":
                readTagExt(call, result);
                return;
            case "writeTagExt":
                writeTagExt(call, result);
                return;
            case "eraseTag":
                eraseTag(call, result);
                return;
            case "findEpc":
                findEpc(call, result);
                return;
            // ── LED 标签 ──────────────────────────────────────────────────
            case "startInventoryLed":
                startInventoryLed(call, result);
                return;
            case "stopInventoryLed":
                stopInventoryLed(result);
                return;
            // ── 掩码 ──────────────────────────────────────────────────────
            case "addMask":
                addMask(call, result);
                return;
            case "addMaskWord":
                addMaskWord(call, result);
                return;
            case "clearMask":
                clearMask(result);
                return;
            // ── 功率与频率 ────────────────────────────────────────────────
            case "setOutputPower":
                setOutputPower(call, result);
                return;
            case "getOutputPower":
                getOutputPower(result);
                return;
            case "getSupportMaxOutputPower":
                getSupportMaxOutputPower(result);
                return;
            case "setFrequencyRegion":
                setFrequencyRegion(call, result);
                return;
            case "getFrequencyRegion":
                getFrequencyRegion(result);
                return;
            case "getSupportFrequencyBandList":
                getSupportFrequencyBandList(result);
                return;
            case "setWorkRegion":
                setWorkRegion(call, result);
                return;
            case "getWorkRegion":
                getWorkRegion(result);
                return;
            case "getSupportWorkRegionList":
                getSupportWorkRegionList(result);
                return;
            case "setCustomRegion":
                setCustomRegion(call, result);
                return;
            case "getCustomRegion":
                getCustomRegion(result);
                return;
            // ── Profile ───────────────────────────────────────────────────
            case "setProfile":
                setProfile(call, result);
                return;
            case "getProfile":
                getProfile(result);
                return;
            case "getSupportProfileList":
                getSupportProfileList(result);
                return;
            // ── 盘存参数 ──────────────────────────────────────────────────
            case "setInventoryWithTarget":
                setInventoryWithTarget(call, result);
                return;
            case "getInventoryWithTarget":
                getInventoryWithTarget(result);
                return;
            case "setInventoryWithSession":
                setInventoryWithSession(call, result);
                return;
            case "getInventoryWithSession":
                getInventoryWithSession(result);
                return;
            case "setInventoryWithStartQvalue":
                setInventoryWithStartQvalue(call, result);
                return;
            case "getInventoryWithStartQvalue":
                getInventoryWithStartQvalue(result);
                return;
            case "setInventoryWithPassword":
                setInventoryWithPassword(call, result);
                return;
            case "getInventoryWithPassword":
                getInventoryWithPassword(result);
                return;
            case "setQueryMemoryBank":
                setQueryMemoryBank(call, result);
                return;
            case "getQueryMemoryBank":
                getQueryMemoryBank(result);
                return;
            case "setInventorySceneMode":
                setInventorySceneMode(call, result);
                return;
            case "getInventorySceneMode":
                getInventorySceneMode(result);
                return;
            case "setInventoryRssiLimit":
                setInventoryRssiLimit(call, result);
                return;
            case "getInventoryRssiLimit":
                getInventoryRssiLimit(result);
                return;
            case "isSupportInventoryRssiLimit":
                isSupportInventoryRssiLimit(result);
                return;
            case "setRssiInDbm":
                setRssiInDbm(call, result);
                return;
            case "setInventoryPhaseFlag":
                setInventoryPhaseFlag(call, result);
                return;
            case "getInventoryPhaseFlag":
                getInventoryPhaseFlag(result);
                return;
            // ── 设备信息 ──────────────────────────────────────────────────
            case "getFirmwareVersion":
                getFirmwareVersion(result);
                return;
            case "getDeviceId":
                getDeviceId(result);
                return;
            case "getReaderType":
                getReaderType(result);
                return;
            case "getEx10Version":
                getEx10Version(result);
                return;
            case "getReaderTemperature":
                getReaderTemperature(result);
                return;
            case "getReaderDeviceType":
                getReaderDeviceType(result);
                return;
            case "getModuleType":
                getModuleType(result);
                return;
            case "setTagFocus":
                setTagFocus(call, result);
                return;
            case "getTagFocus":
                getTagFocus(result);
                return;
            case "setBaudRate":
                setBaudRate(call, result);
                return;
            case "getBaudRate":
                getBaudRate(result);
                return;
            case "setBeepEnable":
                setBeepEnable(call, result);
                return;
            // ── GripDevice ────────────────────────────────────────────────
            case "getBatteryLevel":
                getBatteryLevel(result);
                return;
            case "getBatteryIsCharging":
                getBatteryIsCharging(result);
                return;
            case "getVersionSystem":
                getVersionSystem(result);
                return;
            case "getVersionBLE":
                getVersionBLE(result);
                return;
            case "getVersionMcu":
                getVersionMcu(result);
                return;
            case "getVersionRfid":
                getVersionRfid(result);
                return;
            case "getDeviceSN":
                getDeviceSN(result);
                return;
            case "getBLEMac":
                getBLEMac(result);
                return;
            case "getScanMode":
                getScanMode(result);
                return;
            case "startScanBarcode":
                startScanBarcode(call, result);
                return;
            case "setBeepRange":
                setBeepRange(call, result);
                return;
            case "getBeepRange":
                getBeepRange(result);
                return;
            case "setSleepTime":
                setSleepTime(call, result);
                return;
            case "getSleepTime":
                getSleepTime(result);
                return;
            case "setPowerOffTime":
                setPowerOffTime(call, result);
                return;
            case "getPowerOffTime":
                getPowerOffTime(result);
                return;
            case "setOfflineModeOpen":
                setOfflineModeOpen(call, result);
                return;
            case "getOfflineModeOpen":
                getOfflineModeOpen(result);
                return;
            case "setOfflineTransferClearData":
                setOfflineTransferClearData(call, result);
                return;
            case "getOfflineTransferClearData":
                getOfflineTransferClearData(result);
                return;
            case "setOfflineTransferDelay":
                setOfflineTransferDelay(call, result);
                return;
            case "getOfflineQueryNum":
                getOfflineQueryNum(result);
                return;
            case "getOfflineQueryMem":
                getOfflineQueryMem(result);
                return;
            case "offlineManaulClearScanData":
                offlineManaulClearScanData(result);
                return;
            case "offlineManaulClearRFIDData":
                offlineManaulClearRFIDData(result);
                return;
            case "offlineStartTransferRFID":
                offlineStartTransferRFID(result);
                return;
            case "offlineStartTransferScan":
                offlineStartTransferScan(result);
                return;
            case "modeResetFactory":
                modeResetFactory(result);
                return;
            // ── 固件升级 ──────────────────────────────────────────────────
            case "updateReaderFirmwareByFile":
                updateReaderFirmwareByFile(call, result);
                return;
            case "updateReaderFirmwareByByte":
                updateReaderFirmwareByByte(call, result);
                return;
            case "updateEx10ChipFirmwareByFile":
                updateEx10ChipFirmwareByFile(call, result);
                return;
            case "updateEx10ChipFirmwareByByte":
                updateEx10ChipFirmwareByByte(call, result);
                return;
            case "updateBLEReaderFirmwareByFile":
                updateBLEReaderFirmwareByFile(call, result);
                return;
            case "updateBLEReaderFirmwareByByte":
                updateBLEReaderFirmwareByByte(call, result);
                return;
            case "updateBLEEx10ChipFirmwareByFile":
                updateBLEEx10ChipFirmwareByFile(call, result);
                return;
            case "updateBLEEx10ChipFirmwareByByte":
                updateBLEEx10ChipFirmwareByByte(call, result);
                return;
            // ── Gen2x ─────────────────────────────────────────────────────
            case "setExtProfile":
                setExtProfile(call, result);
                return;
            case "getExtProfile":
                getExtProfile(result);
                return;
            case "setShortRangeFlag":
                setShortRangeFlag(call, result);
                return;
            case "getShortRangeFlag":
                getShortRangeFlag(call, result);
                return;
            case "marginRead":
                marginRead(call, result);
                return;
            case "authenticate":
                authenticate(call, result);
                return;
            case "setPowerBoost":
                setPowerBoost(call, result);
                return;
            case "getPowerBoost":
                getPowerBoost(result);
                return;
            case "setFocus":
                setFocus(call, result);
                return;
            case "getFocus":
                getFocus(result);
                return;
            case "setImpinjScanParam":
                setImpinjScanParam(call, result);
                return;
            case "getImpinjScanParam":
                getImpinjScanParam(result);
                return;
            case "setInventoryMatchData":
                setInventoryMatchData(call, result);
                return;
            case "setTagQueting":
                setTagQueting(call, result);
                return;
            case "getTagQueting":
                getTagQueting(result);
                return;
            case "protectedMode":
                protectedMode(call, result);
                return;
            case "setReaderProtectedMode":
                setReaderProtectedMode(call, result);
                return;
            case "getReaderProtectedMode":
                getReaderProtectedMode(result);
                return;
            default:
                result.notImplemented();
        }
    }

    // ── SDK 生命周期 ───────────────────────────────────────────────────────

    /**
     * Flutter {@link Result} 只能回复一次。URFID 的 {@link InitListener} 在 {@link #releaseRfid}
     * 后仍可能再次 {@code onStatus(false)}，若再次 error/success 会触发 Reply already submitted。
     */
    private static Result wrapOnceResult(final Result delegate) {
        final AtomicBoolean done = new AtomicBoolean(false);
        return new Result() {
            @Override
            public void success(Object result) {
                if (done.compareAndSet(false, true)) {
                    delegate.success(result);
                } else {
                    MLog.d(TAG, ">> Result.success ignored (already replied)");
                }
            }

            @Override
            public void error(String errorCode, String errorMessage, Object errorDetails) {
                if (done.compareAndSet(false, true)) {
                    delegate.error(errorCode, errorMessage, errorDetails);
                } else {
                    MLog.d(TAG, ">> Result.error ignored (already replied): " + errorMessage);
                }
            }

            @Override
            public void notImplemented() {
                if (done.compareAndSet(false, true)) {
                    delegate.notImplemented();
                }
            }
        };
    }

    /**
     * 一体机/UART 设备初始化（无参）。
     * 内部调用 RFIDSDKManager.init(Context, InitListener)。
     */
    private void initSdk(Result result) {
        MLog.d(TAG, ">> initSdk (integrated/UART)");
        final Result once = wrapOnceResult(result);
        final AtomicBoolean awaitingInitReply = new AtomicBoolean(true);
        RFIDSDKManager.getInstance().init(appContext, new InitListener() {
            @Override
            public void onStatus(boolean status) {
                MLog.d(TAG, ">> initSdk onStatus=" + status);
                new Handler(Looper.getMainLooper()).post(() -> {
                    sendEvent(buildEvent(EVENT_CONNECTION, buildConnectionEventData(status)));
                    if (!awaitingInitReply.compareAndSet(true, false)) {
                        MLog.d(TAG, ">> initSdk onStatus after init settled (event only)");
                        return;
                    }
                    if (status) {
                        registerCallbacksAndCacheInfo(once);
                    } else {
                        once.error("-2", "init failed", null);
                    }
                });
            }
        });
    }

    /**
     * 蓝牙设备初始化，传入 MAC 地址。
     * 内部调用 RFIDSDKManager.initBTtoMac(Context, mac, InitListener)。
     * params: mac(String)
     */
    private void initSdkBle(MethodCall call, Result result) {
        String mac = call.argument("mac");
        if (mac == null || mac.isEmpty()) {
            result.error("-1", "mac address is required", null);
            return;
        }
        MLog.d(TAG, ">> initSdkBle mac=" + mac);
        final Result once = wrapOnceResult(result);
        final AtomicBoolean awaitingInitReply = new AtomicBoolean(true);
        RFIDSDKManager.getInstance().initBTtoMac(appContext, mac, new InitListener() {
            @Override
            public void onStatus(boolean status) {
                MLog.d(TAG, ">> initSdkBle onStatus=" + status);
                new Handler(Looper.getMainLooper()).post(() -> {
                    sendEvent(buildEvent(EVENT_CONNECTION, buildConnectionEventData(status)));
                    if (!awaitingInitReply.compareAndSet(true, false)) {
                        MLog.d(TAG, ">> initSdkBle onStatus after init settled (event only)");
                        return;
                    }
                    if (status) {
                        registerCallbacksAndCacheInfo(once);
                    } else {
                        once.error("-2", "initBTtoMac failed", null);
                    }
                });
            }
        });
    }

    /**
     * 两种初始化方式共用：注册所有回调并缓存支持列表
     */
    private void registerCallbacksAndCacheInfo(Result result) {
        try {
            RFIDSDKManager.getInstance().getRfidManager().addDataCallback(dataCallback);
            RFIDSDKManager.getInstance().getRfidManager().setBeepEnable(true);
            GripDeviceManager.getInstance().setBatteryGripListener(batteryGripListener);
            GripDeviceManager.getInstance().registerBarcodeCallback(barcodeCallback);
            GripDeviceManager.getInstance().setKeyEventListener(keyEventListener);
            frequencyBandList = RFIDSDKManager.getInstance().getRfidManager().getSupportFrequencyBandList();
            profileList = RFIDSDKManager.getInstance().getRfidManager().getSupportProfileList();
            // getSupportWorkRegionList 在 SDK 文档中未列出，按需懒加载（见 getSupportWorkRegionList 方法）
            MLog.d(TAG, ">> registerCallbacks ok, freqBands="
                    + (frequencyBandList != null ? frequencyBandList.size() : 0)
                    + " profiles=" + (profileList != null ? profileList.size() : 0));
            new Handler(Looper.getMainLooper()).post(() -> result.success(0));
        } catch (Exception e) {
            MLog.e(TAG, ">> registerCallbacks error", e);
            new Handler(Looper.getMainLooper()).post(() ->
                    result.error("-1", "register callback failed: " + e.getMessage(), null));
        }
    }

    private void releaseSdk(Result result) {
        MLog.d(TAG, ">> releaseSdk");
        releaseRfid();
        result.success(0);
    }

    private void releaseRfid() {
        try {
            GripDeviceManager.getInstance().setBatteryGripListener(null);
            GripDeviceManager.getInstance().registerBarcodeCallback(null);
            GripDeviceManager.getInstance().setKeyEventListener(null);
            RFIDSDKManager.getInstance().release();
        } catch (Exception e) {
            MLog.e(TAG, ">> releaseRfid error", e);
        }
        frequencyBandList = null;
        profileList = null;
    }

    private void isConnected(Result result) {
        try {
            boolean connected = RFIDSDKManager.getInstance().getRfidManager().isConnected();
            result.success(connected);
        } catch (Exception e) {
            result.success(false);
        }
    }

    // ── Guard ──────────────────────────────────────────────────────────────

    private boolean checkReady(Result result) {
        try {
            if (RFIDSDKManager.getInstance().getRfidManager() == null) {
                result.error(String.valueOf(ERR_NO_INIT), "RFID SDK not ready", null);
                return false;
            }
            return true;
        } catch (Exception e) {
            result.error(String.valueOf(ERR_NO_INIT), "RFID SDK not ready: " + e.getMessage(), null);
            return false;
        }
    }

    // ── 盘存 ───────────────────────────────────────────────────────────────

    private void startInventory(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer timeout = call.argument("timeout");
        int ret;
        if (timeout != null) {
            ret = RFIDSDKManager.getInstance().getRfidManager().startInventoryWithTimeout(timeout);
            MLog.d(TAG, ">> startInventory timeout=" + timeout + " ret=" + ret);
        } else {
            ret = RFIDSDKManager.getInstance().getRfidManager().startInventory();
            MLog.d(TAG, ">> startInventory (no timeout) ret=" + ret);
        }
        result.success(ret);
    }

    private void stopInventory(Result result) {
        if (!checkReady(result)) return;
        int ret = RFIDSDKManager.getInstance().getRfidManager().stopInventory();
        MLog.d(TAG, ">> stopInventory ret=" + ret);
        result.success(ret);
    }

    private void inventorySingle(Result result) {
        if (!checkReady(result)) return;
        int ret = RFIDSDKManager.getInstance().getRfidManager().inventorySingle();
        MLog.d(TAG, ">> inventorySingle ret=" + ret);
        result.success(ret);
    }

    // ── 标签操作 ───────────────────────────────────────────────────────────

    private void readTag(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String epc = call.argument("epc");
        Integer memBank = call.argument("memBank");
        Integer wordAdd = call.argument("wordAdd");
        Integer wordCnt = call.argument("wordCnt");
        String password = call.argument("password");
        if (memBank == null || wordAdd == null || wordCnt == null) {
            result.success(buildTagResult(ERR_PARAM, null));
            return;
        }
        TagResult tr = RFIDSDKManager.getInstance().getRfidManager()
                .readTag(epc, memBank, wordAdd, wordCnt, password);
        MLog.d(TAG, ">> readTag code=" + (tr != null ? tr.code : "null"));
        result.success(buildTagResult(tr != null ? tr.code : ERR_PARAM, tr != null ? tr.data : null));
    }

    private void writeTag(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String epc = call.argument("epc");
        String password = call.argument("password");
        Integer memBank = call.argument("memBank");
        Integer wordAdd = call.argument("wordAdd");
        String data = call.argument("data");
        if (memBank == null || wordAdd == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .writeTag(epc, password, memBank, wordAdd, data);
        MLog.d(TAG, ">> writeTag ret=" + ret);
        result.success(ret);
    }

    private void writeTagEpc(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String epc = call.argument("epc");
        String password = call.argument("password");
        String newEpc = call.argument("newEpc");
        int ret = RFIDSDKManager.getInstance().getRfidManager().writeTagEpc(epc, password, newEpc);
        MLog.d(TAG, ">> writeTagEpc ret=" + ret);
        result.success(ret);
    }

    private void writeEpc(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String epc = call.argument("epc");
        String password = call.argument("password");
        int ret = RFIDSDKManager.getInstance().getRfidManager().writeEpc(epc, password);
        MLog.d(TAG, ">> writeEpc ret=" + ret);
        result.success(ret);
    }

    private void killTag(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String epc = call.argument("epc");
        String password = call.argument("password");
        int ret = RFIDSDKManager.getInstance().getRfidManager().killTag(epc, password);
        MLog.d(TAG, ">> killTag ret=" + ret);
        result.success(ret);
    }

    private void lockTag(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String epc = call.argument("epc");
        String password = call.argument("password");
        Integer memBank = call.argument("memBank");
        Integer lockType = call.argument("lockType");
        if (memBank == null || lockType == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .lockTag(epc, password, memBank, lockType);
        MLog.d(TAG, ">> lockTag ret=" + ret);
        result.success(ret);
    }

    private void lightUpLedTag(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String epc = call.argument("epc");
        String password = call.argument("password");
        Integer duration = call.argument("duration");
        int d = duration != null ? duration : 5000;
        int ret = RFIDSDKManager.getInstance().getRfidManager().lightUpLedTag(epc, password, d);
        MLog.d(TAG, ">> lightUpLedTag ret=" + ret);
        result.success(ret);
    }

    // ── TID 操作 ───────────────────────────────────────────────────────────

    private void readDataByTid(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String tid = call.argument("tid");
        Integer memBank = call.argument("memBank");
        Integer startAdd = call.argument("startAdd");
        Integer wordCnt = call.argument("wordCnt");
        String password = call.argument("password");
        if (tid == null || memBank == null || startAdd == null || wordCnt == null) {
            result.success(null);
            return;
        }
        String data = RFIDSDKManager.getInstance().getRfidManager()
                .readDataByTid(tid, memBank, startAdd, wordCnt, password);
        MLog.d(TAG, ">> readDataByTid data=" + data);
        result.success(data);
    }

    private void writeTagByTid(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String tid = call.argument("tid");
        Integer memBank = call.argument("memBank");
        Integer startAdd = call.argument("startAdd");
        String password = call.argument("password");
        String data = call.argument("data");
        if (tid == null || memBank == null || startAdd == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .writeTagByTid(tid, memBank, startAdd, password, data);
        MLog.d(TAG, ">> writeTagByTid ret=" + ret);
        result.success(ret);
    }

    private void lockByTID(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String tid = call.argument("tid");
        Integer lockBank = call.argument("lockBank");
        Integer lockType = call.argument("lockType");
        String password = call.argument("password");
        if (tid == null || lockBank == null || lockType == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .lockByTID(tid, lockBank, lockType, password);
        MLog.d(TAG, ">> lockByTID ret=" + ret);
        result.success(ret);
    }

    private void killTagByTid(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String tid = call.argument("tid");
        String password = call.argument("password");
        if (tid == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().killTagByTid(tid, password);
        MLog.d(TAG, ">> killTagByTid ret=" + ret);
        result.success(ret);
    }

    private void writeTagEpcByTid(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String tid = call.argument("tid");
        String password = call.argument("password");
        String newEpc = call.argument("newEpc");
        if (tid == null || newEpc == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().writeTagEpcByTid(tid, password, newEpc);
        MLog.d(TAG, ">> writeTagEpcByTid ret=" + ret);
        result.success(ret);
    }

    // ── 带掩码操作 ─────────────────────────────────────────────────────────

    private void maskReadTag(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer memBank = call.argument("memBank");
        Integer startAdd = call.argument("startAdd");
        Integer wordCnt = call.argument("wordCnt");
        String password = call.argument("password");
        Integer memMask = call.argument("memMask");
        Integer startMask = call.argument("startMask");
        Integer lenMask = call.argument("lenMask");
        String dataMask = call.argument("dataMask");
        if (memBank == null || startAdd == null || wordCnt == null
                || memMask == null || startMask == null || lenMask == null) {
            result.success(buildTagResult(ERR_PARAM, null));
            return;
        }
        TagResult tr = RFIDSDKManager.getInstance().getRfidManager()
                .maskReadTag(memBank, startAdd, wordCnt, password,
                        memMask, startMask, lenMask, dataMask != null ? dataMask : "");
        MLog.d(TAG, ">> maskReadTag code=" + (tr != null ? tr.code : "null"));
        result.success(buildTagResult(tr != null ? tr.code : ERR_PARAM, tr != null ? tr.data : null));
    }

    private void maskWriteTag(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String data = call.argument("data");
        Integer memBank = call.argument("memBank");
        Integer startAdd = call.argument("startAdd");
        Integer wordCnt = call.argument("wordCnt");
        String password = call.argument("password");
        Integer memMask = call.argument("memMask");
        Integer startMask = call.argument("startMask");
        Integer lenMask = call.argument("lenMask");
        String dataMask = call.argument("dataMask");
        if (memBank == null || startAdd == null || wordCnt == null
                || memMask == null || startMask == null || lenMask == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .maskWriteTag(data, memBank, startAdd, wordCnt, password,
                        memMask, startMask, lenMask, dataMask != null ? dataMask : "");
        MLog.d(TAG, ">> maskWriteTag ret=" + ret);
        result.success(ret);
    }

    // ── 大容量标签 ─────────────────────────────────────────────────────────

    private void readTagExt(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String epc = call.argument("epc");
        Integer memBank = call.argument("memBank");
        Integer startAdd = call.argument("startAdd");
        Integer wordCnt = call.argument("wordCnt");
        String password = call.argument("password");
        if (memBank == null || startAdd == null || wordCnt == null) {
            result.success(buildTagResult(ERR_PARAM, null));
            return;
        }
        TagResult tr = RFIDSDKManager.getInstance().getRfidManager()
                .readTagExt(epc, memBank, startAdd, wordCnt, password);
        MLog.d(TAG, ">> readTagExt code=" + (tr != null ? tr.code : "null"));
        result.success(buildTagResult(tr != null ? tr.code : ERR_PARAM, tr != null ? tr.data : null));
    }

    private void writeTagExt(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String epc = call.argument("epc");
        String password = call.argument("password");
        Integer memBank = call.argument("memBank");
        Integer startAdd = call.argument("startAdd");
        String data = call.argument("data");
        if (memBank == null || startAdd == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .writeTagExt(epc, password, memBank, startAdd, data);
        MLog.d(TAG, ">> writeTagExt ret=" + ret);
        result.success(ret);
    }

    private void eraseTag(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String epc = call.argument("epc");
        String password = call.argument("password");
        Integer memBank = call.argument("memBank");
        Integer startAdd = call.argument("startAdd");
        Integer wordCnt = call.argument("wordCnt");
        if (memBank == null || startAdd == null || wordCnt == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .eraseTag(epc, password, memBank, startAdd, wordCnt);
        MLog.d(TAG, ">> eraseTag ret=" + ret);
        result.success(ret);
    }

    private void findEpc(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String epc = call.argument("epc");
        if (epc == null) {
            result.success(null);
            return;
        }
        Tag6C tag = RFIDSDKManager.getInstance().getRfidManager().findEpc(epc);
        MLog.d(TAG, ">> findEpc tag=" + tag);
        if (tag == null) {
            result.success(null);
            return;
        }
        HashMap<String, Object> map = new HashMap<>();
        map.put("epc", tag.epcId != null ? tag.epcId : "");
        map.put("rssi", tag.rssi);
        result.success(map);
    }

    // ── LED 标签 ───────────────────────────────────────────────────────────

    private void startInventoryLed(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer manufacturers = call.argument("manufacturers");
        List<String> epcs = call.argument("epcs");
        if (manufacturers == null || epcs == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .startInventoryLed(manufacturers, epcs);
        MLog.d(TAG, ">> startInventoryLed ret=" + ret);
        result.success(ret);
    }

    private void stopInventoryLed(Result result) {
        if (!checkReady(result)) return;
        RFIDSDKManager.getInstance().getRfidManager().stopInventoryLed();
        MLog.d(TAG, ">> stopInventoryLed");
        result.success(0);
    }

    // ── 掩码 ───────────────────────────────────────────────────────────────

    private void addMask(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer mem = call.argument("mem");
        Integer addr = call.argument("startAddress");
        Integer len = call.argument("len");
        String data = call.argument("data");
        if (mem == null || addr == null || len == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .addMaskByBits(mem, addr, len, data != null ? data : "");
        MLog.d(TAG, ">> addMask ret=" + ret);
        result.success(ret);
    }

    private void addMaskWord(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer mem = call.argument("mem");
        Integer addr = call.argument("startAddress");
        Integer len = call.argument("len");
        String data = call.argument("data");
        if (mem == null || addr == null || len == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .addMask(mem, addr, len, data != null ? data : "");
        MLog.d(TAG, ">> addMaskWord ret=" + ret);
        result.success(ret);
    }

    private void clearMask(Result result) {
        if (!checkReady(result)) return;
        RFIDSDKManager.getInstance().getRfidManager().clearMask();
        MLog.d(TAG, ">> clearMask");
        result.success(0);
    }

    // ── 功率与频率 ─────────────────────────────────────────────────────────

    private void setOutputPower(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer power = call.argument("power");
        if (power == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().setOutputPower(power);
        MLog.d(TAG, ">> setOutputPower=" + power + " ret=" + ret);
        result.success(ret);
    }

    private void getOutputPower(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().getOutputPower());
    }

    private void getSupportMaxOutputPower(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().getSupportMaxOutputPower());
    }

    private void setFrequencyRegion(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer regionIdx = call.argument("regionIndex");
        Integer minIdx = call.argument("minChannelIndex");
        Integer maxIdx = call.argument("maxChannelIndex");
        if (regionIdx == null || minIdx == null || maxIdx == null
                || frequencyBandList == null || regionIdx >= frequencyBandList.size()) {
            result.success(ERR_PARAM);
            return;
        }
        FrequencyRegion region = frequencyBandList.get(regionIdx);
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .setFrequencyRegion(region, minIdx, maxIdx);
        MLog.d(TAG, ">> setFrequencyRegion region=" + region.getRegionName() + " ret=" + ret);
        result.success(ret);
    }

    private void getFrequencyRegion(Result result) {
        if (!checkReady(result)) return;
        FrequencyRegion region = RFIDSDKManager.getInstance().getRfidManager().getFrequencyRegion();
        if (region == null) {
            result.success(null);
            return;
        }
        HashMap<String, Object> map = new HashMap<>();
        map.put("regionName", region.getRegionName());
        map.put("minChannelIndex", region.getMinChannelIndex());
        map.put("maxChannelIndex", region.getMaxChannelIndex());
        map.put("channelCount", region.getChannelCount());
        int idx = -1;
        if (frequencyBandList != null) {
            for (int i = 0; i < frequencyBandList.size(); i++) {
                if (frequencyBandList.get(i) == region) {
                    idx = i;
                    break;
                }
            }
        }
        map.put("regionIndex", idx);
        result.success(map);
    }

    private void getSupportFrequencyBandList(Result result) {
        if (!checkReady(result)) return;
        if (frequencyBandList == null) {
            frequencyBandList = RFIDSDKManager.getInstance().getRfidManager().getSupportFrequencyBandList();
        }
        List<String> names = new ArrayList<>();
        if (frequencyBandList != null) {
            for (FrequencyRegion r : frequencyBandList) names.add(r.getRegionName());
        }
        result.success(names);
    }

    private void setWorkRegion(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer idx = call.argument("countryCodeIndex");
        CountryCode[] codes = CountryCode.values();
        if (idx == null || idx < 0 || idx >= codes.length) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().setWorkRegion(codes[idx]);
        MLog.d(TAG, ">> setWorkRegion=" + codes[idx] + " ret=" + ret);
        result.success(ret);
    }

    private void getWorkRegion(Result result) {
        if (!checkReady(result)) return;
        CountryCode code = RFIDSDKManager.getInstance().getRfidManager().getWorkRegion();
        if (code == null) {
            result.success(-1);
            return;
        }
        CountryCode[] codes = CountryCode.values();
        int idx = -1;
        for (int i = 0; i < codes.length; i++) {
            if (codes[i] == code) {
                idx = i;
                break;
            }
        }
        result.success(idx);
    }

    private void getSupportWorkRegionList(Result result) {
        // SDK 文档未提供 getSupportWorkRegionList()，直接返回 CountryCode 枚举全集
        List<String> names = new ArrayList<>();
        for (CountryCode c : CountryCode.values()) names.add(c.name());
        result.success(names);
    }

    private void setCustomRegion(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer band = call.argument("band");
        Integer freSpace = call.argument("freSpace");
        Integer freNum = call.argument("freNum");
        Integer startFre = call.argument("startFre");
        if (band == null || freSpace == null || freNum == null || startFre == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .setCustomRegion(band, freSpace, freNum, startFre);
        MLog.d(TAG, ">> setCustomRegion ret=" + ret);
        result.success(ret);
    }

    private void getCustomRegion(Result result) {
        if (!checkReady(result)) return;
        CustomRegionBean bean = RFIDSDKManager.getInstance().getRfidManager().getCustomRegion();
        if (bean == null) {
            result.success(null);
            return;
        }
        // CustomRegionBean 字段均为 int[]，取第一个元素
        HashMap<String, Object> map = new HashMap<>();
        map.put("band", bean.band != null && bean.band.length > 0 ? bean.band[0] : 0);
        map.put("freSpace", bean.FreSpace != null && bean.FreSpace.length > 0 ? bean.FreSpace[0] : 0);
        map.put("freNum", bean.FreNum != null && bean.FreNum.length > 0 ? bean.FreNum[0] : 0);
        map.put("startFre", bean.StartFre != null && bean.StartFre.length > 0 ? bean.StartFre[0] : 0);
        MLog.d(TAG, ">> getCustomRegion band=" + map.get("band"));
        result.success(map);
    }

    // ── Profile ────────────────────────────────────────────────────────────

    private void setProfile(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer idx = call.argument("profileIndex");
        if (idx == null || profileList == null || idx >= profileList.size()) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().setProfile(profileList.get(idx));
        MLog.d(TAG, ">> setProfile idx=" + idx + " ret=" + ret);
        result.success(ret);
    }

    private void getProfile(Result result) {
        if (!checkReady(result)) return;
        RfidProfile profile = RFIDSDKManager.getInstance().getRfidManager().getProfile();
        if (profile == null) {
            result.success(-1);
            return;
        }
        int idx = -1;
        if (profileList != null) {
            for (int i = 0; i < profileList.size(); i++) {
                if (profileList.get(i) == profile) {
                    idx = i;
                    break;
                }
            }
        }
        result.success(idx);
    }

    private void getSupportProfileList(Result result) {
        if (!checkReady(result)) return;
        if (profileList == null) {
            profileList = RFIDSDKManager.getInstance().getRfidManager().getSupportProfileList();
        }
        List<String> names = new ArrayList<>();
        if (profileList != null) {
            for (RfidProfile p : profileList) {
                names.add(String.format("%s BLF:%.0fkHz M:%d", p.value(), p.getBLFKhz(), p.getMiller()));
            }
        }
        result.success(names);
    }

    // ── 盘存参数 ───────────────────────────────────────────────────────────

    private void setInventoryWithTarget(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer target = call.argument("target");
        if (target == null) {
            result.success(ERR_PARAM);
            return;
        }
        result.success(RFIDSDKManager.getInstance().getRfidManager().setInventoryWithTarget(target));
    }

    private void getInventoryWithTarget(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().getInventoryWithTarget());
    }

    private void setInventoryWithSession(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer session = call.argument("session");
        if (session == null) {
            result.success(ERR_PARAM);
            return;
        }
        result.success(RFIDSDKManager.getInstance().getRfidManager().setInventoryWithSession(session));
    }

    private void getInventoryWithSession(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().getInventoryWithSession());
    }

    private void setInventoryWithStartQvalue(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer qvalue = call.argument("qvalue");
        if (qvalue == null) {
            result.success(ERR_PARAM);
            return;
        }
        result.success(RFIDSDKManager.getInstance().getRfidManager().setInventoryWithStartQvalue(qvalue));
    }

    private void getInventoryWithStartQvalue(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().getInventoryWithStartQvalue());
    }

    private void setInventoryWithPassword(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String password = call.argument("password");
        if (password == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().setInventoryWithPassword(password);
        MLog.d(TAG, ">> setInventoryWithPassword ret=" + ret);
        result.success(ret);
    }

    private void getInventoryWithPassword(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().getInventoryWithPassword());
    }

    private void setQueryMemoryBank(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer area = call.argument("area");
        Integer start = call.argument("startAddress");
        Integer len = call.argument("length");
        if (area == null || start == null || len == null) {
            result.success(ERR_PARAM);
            return;
        }
        QueryMemBank bank = QueryMemBank.fromOrdinal(area);
        result.success(RFIDSDKManager.getInstance().getRfidManager().setQueryMemoryBank(bank, start, len));
    }

    private void getQueryMemoryBank(Result result) {
        if (!checkReady(result)) return;
        QueryMemBank bank = RFIDSDKManager.getInstance().getRfidManager().getQueryMemoryBank();
        if (bank == null) {
            result.success(null);
            return;
        }
        HashMap<String, Object> map = new HashMap<>();
        map.put("area", bank.ordinal());
        map.put("startAddress", bank.getStartAddress());
        map.put("length", bank.getReadLength());
        result.success(map);
    }

    private void setInventorySceneMode(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer mode = call.argument("mode");
        if (mode == null) {
            result.success(ERR_PARAM);
            return;
        }
        result.success(RFIDSDKManager.getInstance().getRfidManager()
                .setInventorySceneMode(InventorySceneMode.fromValue(mode)));
    }

    private void getInventorySceneMode(Result result) {
        if (!checkReady(result)) return;
        InventorySceneMode mode = RFIDSDKManager.getInstance().getRfidManager().getInventorySceneMode();
        result.success(mode != null ? mode.getValue() : -1);
    }

    private void setInventoryRssiLimit(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer limit = call.argument("limit");
        if (limit == null) {
            result.success(ERR_PARAM);
            return;
        }
        result.success(RFIDSDKManager.getInstance().getRfidManager().setInventoryRssiLimit(limit));
    }

    private void getInventoryRssiLimit(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().getInventoryRssiLimit());
    }

    private void isSupportInventoryRssiLimit(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().isSupportInventoryRssiLimit());
    }

    private void setRssiInDbm(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Boolean enable = call.argument("enable");
        if (enable == null) {
            result.success(ERR_PARAM);
            return;
        }
        RFIDSDKManager.getInstance().getRfidManager().setRssiInDbm(enable);
        int ret = 0;
        MLog.d(TAG, ">> setRssiInDbm=" + enable + " ret=" + ret);
        result.success(ret);
    }

    private void setInventoryPhaseFlag(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Boolean enable = call.argument("enable");
        if (enable == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().setInventoryPhaseFlag(enable);
        MLog.d(TAG, ">> setInventoryPhaseFlag=" + enable + " ret=" + ret);
        result.success(ret);
    }

    private void getInventoryPhaseFlag(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().getInventoryPhaseFlag());
    }

    // ── 设备信息 ───────────────────────────────────────────────────────────

    private void getFirmwareVersion(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().getFirmwareVersion());
    }

    private void getDeviceId(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().getDeviceId());
    }

    private void getReaderType(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().getReaderType());
    }

    private void getEx10Version(Result result) {
        if (!checkReady(result)) return;
        try {
            result.success(RFIDSDKManager.getInstance().getRfidManager().getEx10Version().versionInfo);
        } catch (Exception e) {
            result.success(null);
        }
    }

    private void getReaderTemperature(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().getReaderTemperature());
    }

    private void getReaderDeviceType(Result result) {
        if (!checkReady(result)) return;
        int type = RFIDSDKManager.getInstance().getRfidManager().getReaderDeviceType();
        result.success(type);
    }

    private void getModuleType(Result result) {
        if (!checkReady(result)) return;
        ModuleType type = RFIDSDKManager.getInstance().getRfidManager().getModuleType();
        result.success(type != null ? type.ordinal() : -1);
    }

    private void setTagFocus(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer enable = call.argument("enable");
        if (enable == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().setTagFocus(enable);
        MLog.d(TAG, ">> setTagFocus=" + enable + " ret=" + ret);
        result.success(ret);
    }

    private void getTagFocus(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().getTagFocus());
    }

    private void setBaudRate(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer baudRate = call.argument("baudRate");
        if (baudRate == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().setBaudRate(baudRate);
        MLog.d(TAG, ">> setBaudRate=" + baudRate + " ret=" + ret);
        result.success(ret);
    }

    private void getBaudRate(Result result) {
        if (!checkReady(result)) return;
        result.success(RFIDSDKManager.getInstance().getRfidManager().getBaudRate());
    }

    private void setBeepEnable(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Boolean enable = call.argument("enable");
        if (enable == null) {
            result.success(ERR_PARAM);
            return;
        }
        RFIDSDKManager.getInstance().getRfidManager().setBeepEnable(enable);
        MLog.d(TAG, ">> setBeepEnable=" + enable);
        result.success(0);
    }

    // ── GripDevice ─────────────────────────────────────────────────────────

    private void getBatteryLevel(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().getElectricQuantity());
        } catch (Exception e) {
            MLog.e(TAG, ">> getBatteryLevel error", e);
            result.success(-1);
        }
    }

    private void getBatteryIsCharging(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().getIsChange());
        } catch (Exception e) {
            MLog.e(TAG, ">> getBatteryIsCharging error", e);
            result.success(-1);
        }
    }

    private void getVersionSystem(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().getVersionSystem());
        } catch (Exception e) {
            MLog.e(TAG, ">> getVersionSystem error", e);
            result.success(null);
        }
    }

    private void getVersionBLE(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().getVersionBLE());
        } catch (Exception e) {
            MLog.e(TAG, ">> getVersionBLE error", e);
            result.success(null);
        }
    }

    private void getVersionMcu(Result result) {
        // GripDeviceManager 无 getVersionMcu，返回 null（不支持）
        MLog.d(TAG, ">> getVersionMcu: not supported by GripDeviceManager");
        result.success(null);
    }

    private void getVersionRfid(Result result) {
        // GripDeviceManager 无 getVersionRfid，返回扫码模块版本 getVersionScan 作为替代
        try {
            result.success(GripDeviceManager.getInstance().getVersionScan());
        } catch (Exception e) {
            MLog.e(TAG, ">> getVersionRfid(getVersionScan) error", e);
            result.success(null);
        }
    }

    private void getDeviceSN(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().getDeviceSN());
        } catch (Exception e) {
            MLog.e(TAG, ">> getDeviceSN error", e);
            result.success(null);
        }
    }

    private void getBLEMac(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().getBLEMac());
        } catch (Exception e) {
            MLog.e(TAG, ">> getBLEMac error", e);
            result.success(null);
        }
    }

    private void getScanMode(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().getScanMode());
        } catch (Exception e) {
            MLog.e(TAG, ">> getScanMode error", e);
            result.success(-1);
        }
    }

    private void startScanBarcode(MethodCall call, Result result) {
        try {
            Boolean start = call.argument("start");
            if (start == null) {
                result.success(ERR_PARAM);
                return;
            }
            int ret = GripDeviceManager.getInstance().startScanBarcode(start);
            MLog.d(TAG, ">> startScanBarcode start=" + start + " ret=" + ret);
            result.success(ret);
        } catch (Exception e) {
            MLog.e(TAG, ">> startScanBarcode error", e);
            result.success(-1);
        }
    }

    private void setBeepRange(MethodCall call, Result result) {
        try {
            Integer volume = call.argument("volume");
            if (volume == null) {
                result.success(ERR_PARAM);
                return;
            }
            int ret = GripDeviceManager.getInstance().setBeepRange(volume);
            MLog.d(TAG, ">> setBeepRange=" + volume + " ret=" + ret);
            result.success(ret);
        } catch (Exception e) {
            MLog.e(TAG, ">> setBeepRange error", e);
            result.success(-1);
        }
    }

    private void getBeepRange(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().getBeepRange());
        } catch (Exception e) {
            MLog.e(TAG, ">> getBeepRange error", e);
            result.success(-1);
        }
    }

    private void setSleepTime(MethodCall call, Result result) {
        try {
            Integer seconds = call.argument("seconds");
            if (seconds == null) {
                result.success(ERR_PARAM);
                return;
            }
            int ret = GripDeviceManager.getInstance().setSleepTime(seconds);
            MLog.d(TAG, ">> setSleepTime=" + seconds + " ret=" + ret);
            result.success(ret);
        } catch (Exception e) {
            MLog.e(TAG, ">> setSleepTime error", e);
            result.success(-1);
        }
    }

    private void getSleepTime(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().getSleepTime());
        } catch (Exception e) {
            MLog.e(TAG, ">> getSleepTime error", e);
            result.success(-1);
        }
    }

    private void setPowerOffTime(MethodCall call, Result result) {
        try {
            Integer seconds = call.argument("seconds");
            if (seconds == null) {
                result.success(ERR_PARAM);
                return;
            }
            int ret = GripDeviceManager.getInstance().setPowerOffTime(seconds);
            MLog.d(TAG, ">> setPowerOffTime=" + seconds + " ret=" + ret);
            result.success(ret);
        } catch (Exception e) {
            MLog.e(TAG, ">> setPowerOffTime error", e);
            result.success(-1);
        }
    }

    private void getPowerOffTime(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().getPowerOffTime());
        } catch (Exception e) {
            MLog.e(TAG, ">> getPowerOffTime error", e);
            result.success(-1);
        }
    }

    private void setOfflineModeOpen(MethodCall call, Result result) {
        try {
            Integer enable = call.argument("enable");
            if (enable == null) {
                result.success(ERR_PARAM);
                return;
            }
            int ret = GripDeviceManager.getInstance().setOfflineModeOpen(enable);
            MLog.d(TAG, ">> setOfflineModeOpen=" + enable + " ret=" + ret);
            result.success(ret);
        } catch (Exception e) {
            MLog.e(TAG, ">> setOfflineModeOpen error", e);
            result.success(-1);
        }
    }

    private void getOfflineModeOpen(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().getOfflineModeOpen());
        } catch (Exception e) {
            MLog.e(TAG, ">> getOfflineModeOpen error", e);
            result.success(-1);
        }
    }

    private void setOfflineTransferClearData(MethodCall call, Result result) {
        try {
            Integer enable = call.argument("enable");
            if (enable == null) {
                result.success(ERR_PARAM);
                return;
            }
            int ret = GripDeviceManager.getInstance().setOfflineTransferClearData(enable);
            MLog.d(TAG, ">> setOfflineTransferClearData=" + enable + " ret=" + ret);
            result.success(ret);
        } catch (Exception e) {
            MLog.e(TAG, ">> setOfflineTransferClearData error", e);
            result.success(-1);
        }
    }

    private void getOfflineTransferClearData(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().getOfflineTransferClearData());
        } catch (Exception e) {
            MLog.e(TAG, ">> getOfflineTransferClearData error", e);
            result.success(-1);
        }
    }

    private void setOfflineTransferDelay(MethodCall call, Result result) {
        try {
            Integer ms = call.argument("ms");
            if (ms == null) {
                result.success(ERR_PARAM);
                return;
            }
            int ret = GripDeviceManager.getInstance().setOfflineTransferDelay(ms);
            MLog.d(TAG, ">> setOfflineTransferDelay=" + ms + " ret=" + ret);
            result.success(ret);
        } catch (Exception e) {
            MLog.e(TAG, ">> setOfflineTransferDelay error", e);
            result.success(-1);
        }
    }

    private void getOfflineQueryNum(Result result) {
        try {
            int[] nums = GripDeviceManager.getInstance().getOfflineQueryNum();
            HashMap<String, Object> map = new HashMap<>();
            map.put("rfidCount", nums != null && nums.length > 0 ? nums[0] : 0);
            map.put("barcodeCount", nums != null && nums.length > 1 ? nums[1] : 0);
            result.success(map);
        } catch (Exception e) {
            MLog.e(TAG, ">> getOfflineQueryNum error", e);
            result.success(null);
        }
    }

    private void getOfflineQueryMem(Result result) {
        try {
            double[] mems = GripDeviceManager.getInstance().getOfflineQueryMem();
            HashMap<String, Object> map = new HashMap<>();
            map.put("rfidPercent", mems != null && mems.length > 0 ? mems[0] : 0.0);
            map.put("barcodePercent", mems != null && mems.length > 1 ? mems[1] : 0.0);
            result.success(map);
        } catch (Exception e) {
            MLog.e(TAG, ">> getOfflineQueryMem error", e);
            result.success(null);
        }
    }

    private void offlineManaulClearScanData(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().offlineManaulClearScanData());
        } catch (Exception e) {
            MLog.e(TAG, ">> offlineManaulClearScanData error", e);
            result.success(-1);
        }
    }

    private void offlineManaulClearRFIDData(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().offlineManaulClearRFIDData());
        } catch (Exception e) {
            MLog.e(TAG, ">> offlineManaulClearRFIDData error", e);
            result.success(-1);
        }
    }

    private void offlineStartTransferRFID(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().offlineStartTransferRFID());
        } catch (Exception e) {
            MLog.e(TAG, ">> offlineStartTransferRFID error", e);
            result.success(-1);
        }
    }

    private void offlineStartTransferScan(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().offlineStartTransferScan());
        } catch (Exception e) {
            MLog.e(TAG, ">> offlineStartTransferScan error", e);
            result.success(-1);
        }
    }

    private void modeResetFactory(Result result) {
        try {
            result.success(GripDeviceManager.getInstance().modeResetFactory());
        } catch (Exception e) {
            MLog.e(TAG, ">> modeResetFactory error", e);
            result.success(-1);
        }
    }

    // ── 固件升级 ───────────────────────────────────────────────────────────

    /**
     * 构建统一的固件升级进度回调，通过 EventChannel 推送 event_fw_update
     */
    private FWUpdateCallback buildFwCallback() {
        return new FWUpdateCallback() {
            @Override
            public void updateResult(int code) {
                // code: 0=成功, 11=失败, 13=进入升级模式失败, 14=进入升级模式成功
                MLog.d(TAG, ">> FWUpdate updateResult code=" + code);
                HashMap<String, Object> data = new HashMap<>();
                data.put("code", code);
                data.put("progress", 100);
                sendEvent(buildEvent(EVENT_FW_UPDATE, data));
            }

            @Override
            public void updateProcess(int progress) {
                // progress: 0~100
                MLog.d(TAG, ">> FWUpdate updateProcess progress=" + progress);
                HashMap<String, Object> data = new HashMap<>();
                data.put("code", 12); // 12=升级中
                data.put("progress", progress);
                sendEvent(buildEvent(EVENT_FW_UPDATE, data));
            }
        };
    }

    private void updateReaderFirmwareByFile(MethodCall call, Result result) {
        String binName = call.argument("binName");
        String binPath = call.argument("binPath");
        if (binName == null || binPath == null) {
            result.success(ERR_PARAM);
            return;
        }
        FirmwareManager.getInstance().updateReaderFirmwareByFile(
                appContext, buildFwCallback(), binName, binPath);
        MLog.d(TAG, ">> updateReaderFirmwareByFile binName=" + binName);
        result.success(0);
    }

    private void updateReaderFirmwareByByte(MethodCall call, Result result) {
        String binName = call.argument("binName");
        byte[] data = call.argument("data");
        if (binName == null || data == null) {
            result.success(ERR_PARAM);
            return;
        }
        FirmwareManager.getInstance().updateReaderFirmwareByByte(
                appContext, buildFwCallback(), binName, data);
        MLog.d(TAG, ">> updateReaderFirmwareByByte binName=" + binName);
        result.success(0);
    }

    private void updateEx10ChipFirmwareByFile(MethodCall call, Result result) {
        String binPath = call.argument("binPath");
        if (binPath == null) {
            result.success(ERR_PARAM);
            return;
        }
        FirmwareManager.getInstance().updateEx10ChipFirmwareByFile(
                appContext, buildFwCallback(), binPath);
        MLog.d(TAG, ">> updateEx10ChipFirmwareByFile binPath=" + binPath);
        result.success(0);
    }

    private void updateEx10ChipFirmwareByByte(MethodCall call, Result result) {
        byte[] data = call.argument("data");
        if (data == null) {
            result.success(ERR_PARAM);
            return;
        }
        FirmwareManager.getInstance().updateEx10ChipFirmwareByByte(
                appContext, buildFwCallback(), data);
        MLog.d(TAG, ">> updateEx10ChipFirmwareByByte");
        result.success(0);
    }

    private void updateBLEReaderFirmwareByFile(MethodCall call, Result result) {
        String mac = call.argument("mac");
        String binName = call.argument("binName");
        String binPath = call.argument("binPath");
        if (mac == null || binName == null || binPath == null) {
            result.success(ERR_PARAM);
            return;
        }
        FirmwareManager.getInstance().updateBLEReaderFirmwareByFile(
                appContext, mac, buildFwCallback(), binName, binPath);
        MLog.d(TAG, ">> updateBLEReaderFirmwareByFile mac=" + mac + " binName=" + binName);
        result.success(0);
    }

    private void updateBLEReaderFirmwareByByte(MethodCall call, Result result) {
        String mac = call.argument("mac");
        String binName = call.argument("binName");
        byte[] data = call.argument("data");
        if (mac == null || binName == null || data == null) {
            result.success(ERR_PARAM);
            return;
        }
        FirmwareManager.getInstance().updateBLEReaderFirmwareByByte(
                appContext, mac, buildFwCallback(), binName, data);
        MLog.d(TAG, ">> updateBLEReaderFirmwareByByte mac=" + mac + " binName=" + binName);
        result.success(0);
    }

    private void updateBLEEx10ChipFirmwareByFile(MethodCall call, Result result) {
        String mac = call.argument("mac");
        String binPath = call.argument("binPath");
        if (mac == null || binPath == null) {
            result.success(ERR_PARAM);
            return;
        }
        FirmwareManager.getInstance().updateBLEEx10ChipFirmwareByFile(
                appContext, mac, buildFwCallback(), binPath);
        MLog.d(TAG, ">> updateBLEEx10ChipFirmwareByFile mac=" + mac);
        result.success(0);
    }

    private void updateBLEEx10ChipFirmwareByByte(MethodCall call, Result result) {
        String mac = call.argument("mac");
        byte[] data = call.argument("data");
        if (mac == null || data == null) {
            result.success(ERR_PARAM);
            return;
        }
        // SDK 签名：updateBLEEx10ChipFirmwareByByte(Context, address, FWUpdateCallback, byte[])
        // 无 binName 参数
        FirmwareManager.getInstance().updateBLEEx10ChipFirmwareByByte(
                appContext, mac, buildFwCallback(), data);
        MLog.d(TAG, ">> updateBLEEx10ChipFirmwareByByte mac=" + mac);
        result.success(0);
    }

    // ── Gen2x ──────────────────────────────────────────────────────────────

    private void setExtProfile(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer profile = call.argument("profile");
        if (profile == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().setExtProfile(profile);
        MLog.d(TAG, ">> setExtProfile=" + profile + " ret=" + ret);
        result.success(ret);
    }

    private void getExtProfile(Result result) {
        if (!checkReady(result)) return;
        int ret = RFIDSDKManager.getInstance().getRfidManager().getExtProfile();
        MLog.d(TAG, ">> getExtProfile=" + ret);
        result.success(ret);
    }

    private void setShortRangeFlag(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer epcNum = call.argument("epcNum");
        String strEPC = call.argument("strEPC");
        String password = call.argument("password");
        Integer maskMem = call.argument("maskMem");
        Integer btWordAdd = call.argument("btWordAdd");
        Integer maskLength = call.argument("maskLength");
        String maskData = call.argument("maskData");
        Integer srBit = call.argument("srBit");
        Integer srValue = call.argument("srValue");
        if (epcNum == null || maskMem == null || btWordAdd == null
                || maskLength == null || srBit == null || srValue == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().setShortRangeFlag(
                epcNum, strEPC != null ? strEPC : "",
                password != null ? password : "",
                maskMem, btWordAdd, maskLength.byteValue(),
                maskData != null ? maskData : "", srBit, srValue);
        MLog.d(TAG, ">> setShortRangeFlag ret=" + ret);
        result.success(ret);
    }

    private void getShortRangeFlag(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer epcNum = call.argument("epcNum");
        String strEPC = call.argument("strEPC");
        String password = call.argument("password");
        Integer maskMem = call.argument("maskMem");
        Integer btWordAdd = call.argument("btWordAdd");
        Integer maskLength = call.argument("maskLength");
        String maskData = call.argument("maskData");
        Integer srBit = call.argument("srBit");
        if (epcNum == null || maskMem == null || btWordAdd == null
                || maskLength == null || srBit == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().getShortRangeFlag(
                epcNum, strEPC != null ? strEPC : "",
                password != null ? password : "",
                maskMem, btWordAdd, maskLength.byteValue(),
                maskData != null ? maskData : "", srBit);
        MLog.d(TAG, ">> getShortRangeFlag ret=" + ret);
        result.success(ret);
    }

    private void marginRead(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer epcNum = call.argument("epcNum");
        String strEPC = call.argument("strEPC");
        Integer memInt = call.argument("memInt");
        Integer address = call.argument("address");
        Integer matchLength = call.argument("matchLength");
        String matchData = call.argument("matchData");
        String password = call.argument("password");
        Integer maskMem = call.argument("maskMem");
        Integer btWordAdd = call.argument("btWordAdd");
        Integer maskLength = call.argument("maskLength");
        String maskData = call.argument("maskData");
        if (epcNum == null || memInt == null || address == null
                || matchLength == null || maskMem == null
                || btWordAdd == null || maskLength == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().marginRead(
                epcNum, strEPC != null ? strEPC : "",
                memInt, address, matchLength.byteValue(),
                matchData != null ? matchData : "",
                password != null ? password : "",
                maskMem, btWordAdd, maskLength,
                maskData != null ? maskData : "");
        MLog.d(TAG, ">> marginRead ret=" + ret);
        result.success(ret);
    }

    private void authenticate(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String epc = call.argument("epc");
        String password = call.argument("password");
        if (epc == null || password == null) {
            result.success(ERR_PARAM);
            return;
        }
        try {
            Object authRes = RFIDSDKManager.getInstance().getRfidManager()
                    .authenticate(epc, password);
            if (authRes == null) {
                result.success(ERR_PARAM);
                return;
            }
            // AuthRes: int code, String random, String response
            java.lang.reflect.Field fCode = authRes.getClass().getField("code");
            java.lang.reflect.Field fRandom = authRes.getClass().getField("random");
            java.lang.reflect.Field fResponse = authRes.getClass().getField("response");
            HashMap<String, Object> map = new HashMap<>();
            map.put("code", fCode.getInt(authRes));
            map.put("random", (String) fRandom.get(authRes));
            map.put("response", (String) fResponse.get(authRes));
            MLog.d(TAG, ">> authenticate code=" + map.get("code"));
            result.success(map);
        } catch (Exception e) {
            MLog.e(TAG, ">> authenticate error", e);
            result.error("AUTH_ERROR", e.getMessage(), null);
        }
    }

    private void setPowerBoost(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer enable = call.argument("enable");
        if (enable == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().setPowerBoost(enable);
        MLog.d(TAG, ">> setPowerBoost=" + enable + " ret=" + ret);
        result.success(ret);
    }

    private void getPowerBoost(Result result) {
        if (!checkReady(result)) return;
        int ret = RFIDSDKManager.getInstance().getRfidManager().getPowerBoost();
        MLog.d(TAG, ">> getPowerBoost=" + ret);
        result.success(ret);
    }

    private void setFocus(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer mode = call.argument("mode");
        if (mode == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().setTagFocus(mode);
        MLog.d(TAG, ">> setFocus=" + mode + " ret=" + ret);
        result.success(ret);
    }

    private void getFocus(Result result) {
        if (!checkReady(result)) return;
        int ret = RFIDSDKManager.getInstance().getRfidManager().getTagFocus();
        MLog.d(TAG, ">> getFocus=" + ret);
        result.success(ret);
    }

    private void setImpinjScanParam(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer opt = call.argument("opt");
        Integer n = call.argument("n");
        Integer code = call.argument("code");
        Integer cr = call.argument("cr");
        Integer protection = call.argument("protection");
        Integer id = call.argument("id");
        Integer copyTo = call.argument("copyTo");
        if (opt == null || n == null || code == null || cr == null
                || protection == null || id == null || copyTo == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .setImpinjScanParam(opt, n, code, cr, protection, id, copyTo);
        MLog.d(TAG, ">> setImpinjScanParam ret=" + ret);
        result.success(ret);
    }

    private void getImpinjScanParam(Result result) {
        if (!checkReady(result)) return;
        int[] aar = RFIDSDKManager.getInstance().getRfidManager().getImpinjScanParam();
        if (aar == null || aar.length < 6) {
            result.success(null);
            return;
        }
        HashMap<String, Object> map = new HashMap<>();
        map.put("n", aar[0]);
        map.put("code", aar[1]);
        map.put("cr", aar[2]);
        map.put("protection", aar[3]);
        map.put("id", aar[4]);
        map.put("copyTo", aar[5]);
        MLog.d(TAG, ">> getImpinjScanParam n=" + aar[0]);
        result.success(map);
    }

    private void setInventoryMatchData(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer matchType = call.argument("matchType");
        List<Map<String, Object>> items = call.argument("items");
        if (matchType == null) {
            result.success(ERR_PARAM);
            return;
        }
        List<MatchData> matchList = new ArrayList<>();
        if (items != null) {
            for (Map<String, Object> item : items) {
                if (item == null) continue;
                String maskData = (String) item.get("maskData");
                int memBank = item.get("memBank") instanceof Number ? ((Number) item.get("memBank")).intValue() : 1;
                int maskStart = item.get("maskStart") instanceof Number ? ((Number) item.get("maskStart")).intValue() : 0;
                int maskLen = item.get("maskLen") instanceof Number ? ((Number) item.get("maskLen")).intValue() : 0;
                matchList.add(new MatchData(maskData != null ? maskData : "", memBank, maskStart, maskLen));
            }
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .setInventoryMatchData(matchType, matchList);
        MLog.d(TAG, ">> setInventoryMatchData matchType=" + matchType + " count=" + matchList.size() + " ret=" + ret);
        result.success(ret);
    }

    private void setTagQueting(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer opt = call.argument("opt");
        Integer enable = call.argument("enable");
        if (opt == null || enable == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager().setTagQueting(opt, enable);
        MLog.d(TAG, ">> setTagQueting opt=" + opt + " enable=" + enable + " ret=" + ret);
        result.success(ret);
    }

    private void getTagQueting(Result result) {
        if (!checkReady(result)) return;
        int ret = RFIDSDKManager.getInstance().getRfidManager().getTagQueting();
        MLog.d(TAG, ">> getTagQueting=" + ret);
        result.success(ret);
    }

    private void protectedMode(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        String epc = call.argument("epc");
        Integer enable = call.argument("enable");
        String password = call.argument("password");
        if (epc == null || enable == null || password == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .protectedMode(epc, enable, password);
        MLog.d(TAG, ">> protectedMode epc=" + epc + " enable=" + enable + " ret=" + ret);
        result.success(ret);
    }

    private void setReaderProtectedMode(MethodCall call, Result result) {
        if (!checkReady(result)) return;
        Integer opt = call.argument("opt");
        Integer enable = call.argument("enable");
        String password = call.argument("password");
        if (opt == null || enable == null || password == null) {
            result.success(ERR_PARAM);
            return;
        }
        int ret = RFIDSDKManager.getInstance().getRfidManager()
                .setReaderProtectedMode(opt, enable, password);
        MLog.d(TAG, ">> setReaderProtectedMode opt=" + opt + " enable=" + enable + " ret=" + ret);
        result.success(ret);
    }

    private void getReaderProtectedMode(Result result) {
        if (!checkReady(result)) return;
        String[] aar = RFIDSDKManager.getInstance().getRfidManager().getReaderProtectedMode();
        if (aar == null || aar.length < 2) {
            result.success(null);
            return;
        }
        HashMap<String, Object> map = new HashMap<>();
        map.put("enable", aar[0]);
        map.put("password", aar[1]);
        MLog.d(TAG, ">> getReaderProtectedMode enable=" + aar[0]);
        result.success(map);
    }

    // ── 工具方法 ───────────────────────────────────────────────────────────

    private HashMap<String, Object> buildEvent(String eventType, Object data) {
        HashMap<String, Object> event = new HashMap<>();
        event.put("eventType", eventType);
        event.put("data", data);
        return event;
    }

    private static HashMap<String, Object> buildConnectionEventData(boolean connected) {
        HashMap<String, Object> m = new HashMap<>();
        m.put("connected", connected);
        return m;
    }

    private HashMap<String, Object> buildTagResult(int code, String data) {
        HashMap<String, Object> map = new HashMap<>();
        map.put("code", code);
        map.put("data", data != null ? data : "");
        return map;
    }

    private void sendEvent(final Object event) {
        new Handler(Looper.getMainLooper()).post(() -> {
            if (eventSink != null) eventSink.success(event);
        });
    }
}
