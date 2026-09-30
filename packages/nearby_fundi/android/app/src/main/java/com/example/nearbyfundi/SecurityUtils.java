// android/app/src/main/java/com/nearbyfundi/SecurityUtils.java
package com.example.nearbyfundi;

import android.app.Activity;
import android.view.WindowManager;

public class SecurityUtils {

    /**
     * Enable secure flag to prevent screenshots
     */
    public static void enableSecureScreen(Activity activity) {
        if (activity != null) {
            activity.getWindow().setFlags(
                    WindowManager.LayoutParams.FLAG_SECURE,
                    WindowManager.LayoutParams.FLAG_SECURE
            );
        }
    }

    /**
     * Disable secure flag to allow screenshots
     */
    public static void disableSecureScreen(Activity activity) {
        if (activity != null) {
            activity.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
        }
    }
}