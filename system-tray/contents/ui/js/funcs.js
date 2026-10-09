.pragma library

function btStatus(btManager) {
    var connectedDevices = [];
    for (var i = 0; i < btManager.devices.length; ++i) {
        var device = btManager.devices[i];
        if (device.connected) {
            connectedDevices.push(device);
        }
    }

    // Bluetooth icon names (per user spec): the tile draws its icon from
    // the Blueberry tray icon family — "blueberry-tray-disabled-symbolic"
    // when powered off / unavailable / blocked, and "blueberry-tray-symbolic"
    // when powered on (with or without connected devices). The on/off
    // distinction is what the icon conveys; the number of connected
    // devices and the friendly device name are surfaced via the `active`
    // flag, the status message, and the tile's tooltip instead.
    if (btManager.bluetoothBlocked) {
        return { active: false, message: i18n("Disabled"), icon: "blueberry-tray-disabled-symbolic" };
    } else if (!btManager.bluetoothOperational) {
        if (!btManager.adapters.length) {
            return { active: false, message: i18n("Unavailable"), icon: "blueberry-tray-disabled-symbolic" };
        }
        return { active: false, message: i18n("Offline"), icon: "blueberry-tray-disabled-symbolic" };
    } else if (connectedDevices.length >= 1) {
        return { active: true, message: connectedDevices[0].name, icon: "blueberry-tray-symbolic" };
    }
    return { active: true, message: i18n("Not Connected"), icon: "blueberry-tray-symbolic" };
}

function toggleBluetooth(btManager) {
    var enable = !btManager.bluetoothOperational;
    btManager.bluetoothBlocked = !enable;
    for (var i = 0; i < btManager.adapters.length; ++i) {
        btManager.adapters[i].powered = enable;
    }
}

function checkInhibition(notificationSettings) {
    if (!notificationSettings) {
        return false;
    }
    var inhibited = false;
    var inhibitedUntil = notificationSettings.notificationsInhibitedUntil;
    if (!isNaN(inhibitedUntil.getTime())) {
        inhibited |= (Date.now() < inhibitedUntil.getTime());
    }
    if (notificationSettings.notificationsInhibitedByApplication) {
        inhibited |= true;
    }
    if (notificationSettings.inhibitNotificationsWhenScreensMirrored) {
        inhibited |= notificationSettings.screensMirrored;
    }
    return inhibited;
}

function toggleDnd(notificationSettings) {
    if (checkInhibition(notificationSettings)) {
        notificationSettings.notificationsInhibitedUntil = undefined;
        notificationSettings.revokeApplicationInhibitions();
        notificationSettings.screensMirrored = false;
        notificationSettings.save();
        return;
    }
    var d = new Date();
    d.setYear(d.getFullYear() + 1);
    notificationSettings.notificationsInhibitedUntil = d;
    notificationSettings.save();
}

function volIconName(volume, muted) {
    var percent = volume / 65536;
    if (percent <= 0.0 || muted) {
        return "audio-volume-muted-symbolic";
    } else if (percent <= 0.25) {
        return "audio-volume-low-symbolic";
    } else if (percent <= 0.75) {
        return "audio-volume-medium-symbolic";
    }
    return "audio-volume-high-symbolic";
}

function batteryIconName(percent, charging) {
    var icon;
    if (percent < 10) {
        icon = "battery-000";
    } else if (percent < 20) {
        icon = "battery-010";
    } else if (percent < 30) {
        icon = "battery-020";
    } else if (percent < 40) {
        icon = "battery-030";
    } else if (percent < 50) {
        icon = "battery-040";
    } else if (percent < 60) {
        icon = "battery-050";
    } else if (percent < 70) {
        icon = "battery-060";
    } else if (percent < 80) {
        icon = "battery-070";
    } else if (percent < 90) {
        icon = "battery-080";
    } else if (percent < 100) {
        icon = "battery-090";
    } else {
        icon = "battery-100";
    }
    return charging ? icon + "-charging-symbolic" : icon + "-symbolic";
}
