package com.example.applauncher

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Arrays;
import android.os.Bundle;
import android.os.Build;
import android.os.Parcelable;
import android.net.Uri;
import android.graphics.drawable.Icon;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ShortcutManager;
import android.content.pm.ShortcutInfo;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.AdaptiveIconDrawable;

class MainActivity: FlutterActivity() {
    private val LOGTAG = "AppLauncher";
    private var currentIntent: Intent? = null;

    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode {
        return BackgroundMode.transparent
    }
  
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
      super.configureFlutterEngine(flutterEngine)
      val appPackageName: String = getApplicationContext().getPackageName()
  
      MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appPackageName).setMethodCallHandler {
        call, result ->
        when(call.method) {
            "createCategoryShortcut" -> {
                val label: String? = call.argument("label");
                val categoryId: Int? = call.argument("category_id");
                val icon: String? = call.argument("icon");
                val iconData: Array<Byte>? = call.argument("icon_data");
                val requestPin: Boolean? = call.argument("request_pin");
                if (label != null && categoryId != null && icon != null && requestPin != null)
                    createCategoryShortcut(label, categoryId, icon, iconData, requestPin);
                result.success(null);
            }
            "deleteCategoryShortcut" -> {
                val catId: Int? = call.argument("category_id");
                if (catId != null)
                    deleteCategoryShortcut(catId);
                result.success(null);
            }
            "deleteAllShortcuts" -> {
                deleteAllShortcuts();
                result.success(null);
            }
            "getShortcutSupport" -> {
                result.success(getShortcutSupport());
            }
            "getParam" -> {
                log("getParam");
                if (currentIntent == null) {
                    result.success(null);
                } else {
                    val extras = currentIntent?.getExtras();
                    if (extras == null) {
                        result.success(null);
                    } else {
                        val paramType: String? = call.argument("type");
                        val paramKey: String? = call.argument("key");
                        when (paramType) {
                            "string" -> {
                                val valStr: String? = extras.getString(paramKey);
                                result.success(valStr);
                            }
                            "int" -> {
                                val valInt: Int = extras.getInt(paramKey);
                                result.success(valInt);
                            }
                            else ->
                                result.error("ParamTypeError", "Param type " + paramType + " is not implemented", null);
                        }
                        currentIntent = null;
                    }
                }
            }
            else -> {
                result.notImplemented();
            }        
          }
      }
    }

    override fun onCreate(bundle: Bundle?) {
        super.onCreate(bundle);
        currentIntent = getIntent();
        log("onCreate");
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        currentIntent = intent
        log("onNewIntent")
    }  
  
    private fun deleteCategoryShortcut(categoryId: Int) {
        if (getShortcutSupport() > 1) {
          val shortcutManager = getSystemService(ShortcutManager::class.java);
          shortcutManager.removeDynamicShortcuts(Arrays.asList("category_id" + categoryId));
        }
    }
  
    private fun deleteAllShortcuts() {
      if (getShortcutSupport() > 1) {
        val shortcutManager = getSystemService(ShortcutManager::class.java)
        shortcutManager.removeAllDynamicShortcuts()
      }
  }  
  
    private fun convertBitmapToAdaptive(bitmap: Bitmap, context: Context): Bitmap {
      val bitmapDrawable = BitmapDrawable(context.getResources(), bitmap)
      val drawableIcon = AdaptiveIconDrawable(bitmapDrawable, bitmapDrawable);
      val result = Bitmap.createBitmap(drawableIcon.getIntrinsicWidth(), drawableIcon.getIntrinsicHeight(), Bitmap.Config.ARGB_8888)
      val canvas = Canvas(result)
      drawableIcon.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
      drawableIcon.draw(canvas);
      return result;
    }
  
    private fun createCategoryShortcut(label: String, categoryId: Int, iconKey: String, iconData: Array<Byte>?, requestPin: Boolean) {
      val context = getApplicationContext()
      var shortcutIcon: Icon
      var icon: Int = context.getResources().getIdentifier(iconKey, "drawable", context.getPackageName())
      if (iconData != null && iconData.size > 0) {
          var bmIcon: Bitmap = convertBitmapToAdaptive(BitmapFactory.decodeByteArray(iconData.toByteArray(), 0, iconData.size), context);
          shortcutIcon = Icon.createWithAdaptiveBitmap(convertBitmapToAdaptive(bmIcon, context));
      } else {
          shortcutIcon = Icon.createWithResource(this, icon);
      }
      val shortcutIntent = Intent(this, MainActivity::class.java);
      shortcutIntent.setAction(Intent.ACTION_MAIN);
      shortcutIntent.putExtra("category_id", categoryId);
  
      if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
          val intent = Intent("com.android.launcher.action.INSTALL_SHORTCUT");
          intent.putExtra(Intent.EXTRA_SHORTCUT_INTENT, shortcutIntent);
          intent.putExtra(Intent.EXTRA_SHORTCUT_NAME, label);
          intent.putExtra("duplicate", false);
          val parcelable = Intent.ShortcutIconResource.fromContext(this, icon);
          intent.putExtra(Intent.EXTRA_SHORTCUT_ICON_RESOURCE, parcelable);
          sendBroadcast(intent);
      } else { 
          val shortcutManager = getSystemService(ShortcutManager::class.java);
          val pinShortcutInfo = ShortcutInfo.Builder(context, "category_" + categoryId)
                  .setIntent(shortcutIntent)
                  .setIcon(shortcutIcon)
                  .setShortLabel(label)
                  .build();
          if (requestPin) {
              if (shortcutManager.isRequestPinShortcutSupported()) {
                  shortcutManager.requestPinShortcut(pinShortcutInfo, null);
              }
          } else {
              shortcutManager.addDynamicShortcuts(Arrays.asList(pinShortcutInfo));
          }
      }    
    }
  
    private fun getShortcutSupport(): Int {
      if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
          return 1;
      } else { 
          val shortcutManager: ShortcutManager = getSystemService(ShortcutManager::class.java)
          if (shortcutManager == null) {
              return -1;
          }
          if (shortcutManager.isRequestPinShortcutSupported()) {
              return 2;
          } else {
              return 3;
          }
      }         
    }    
  
    private fun log(message: String) {
      Log.d(LOGTAG, message);
    }
}
