package com.urovo.rfid;

import android.util.Log;

/**
 * 统一日志工具，所有日志以 ">>" 前缀输出，便于过滤查看。
 * Unified log utility. All logs are prefixed with ">>" for easy filtering.
 */
public class MLog {
    private static final String DEFAULT_TAG = "RfidPlugin";

    public static void d(String tag, String msg) {
        Log.d(tag, ">> " + msg);
    }

    public static void i(String tag, String msg) {
        Log.i(tag, ">> " + msg);
    }

    public static void w(String tag, String msg) {
        Log.w(tag, ">> " + msg);
    }

    public static void e(String tag, String msg) {
        Log.e(tag, ">> " + msg);
    }

    public static void e(String tag, String msg, Throwable tr) {
        Log.e(tag, ">> " + msg, tr);
    }

    public static void d(String msg) {
        Log.d(DEFAULT_TAG, ">> " + msg);
    }
}
