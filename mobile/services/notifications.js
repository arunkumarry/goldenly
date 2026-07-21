import * as Device from "expo-device";
import * as Notifications from "expo-notifications";
import Constants from "expo-constants";
import { Platform } from "react-native";
import * as SecureStore from "expo-secure-store";

const PUSH_TOKEN_KEY = "goldenly_expo_push_token";
const ANDROID_CHANNEL_ID = "care-reminders";

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: true,
    shouldSetBadge: false
  })
});

async function notificationPermissionGranted() {
  let permissions = await Notifications.getPermissionsAsync();
  if (!permissions.granted) permissions = await Notifications.requestPermissionsAsync();
  return permissions.granted;
}

async function configureAndroidChannel() {
  if (Platform.OS !== "android") return;

  await Notifications.setNotificationChannelAsync(ANDROID_CHANNEL_ID, {
    name: "Care reminders",
    importance: Notifications.AndroidImportance.HIGH,
    vibrationPattern: [0, 250, 250, 250],
    sound: "default"
  });
}

function futureDate(value) {
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) || date <= new Date() ? null : date;
}

function reminderTrigger(reminder) {
  const scheduledFor = futureDate(reminder.scheduled_for);
  if (!scheduledFor) return null;

  const channel = Platform.OS === "android" ? { channelId: ANDROID_CHANNEL_ID } : {};
  if (reminder.recurrence === "daily") {
    return { type: Notifications.SchedulableTriggerInputTypes.DAILY, hour: scheduledFor.getHours(), minute: scheduledFor.getMinutes(), ...channel };
  }
  if (reminder.recurrence === "weekly") {
    return { type: Notifications.SchedulableTriggerInputTypes.WEEKLY, weekday: scheduledFor.getDay() + 1, hour: scheduledFor.getHours(), minute: scheduledFor.getMinutes(), ...channel };
  }

  return { type: Notifications.SchedulableTriggerInputTypes.DATE, date: scheduledFor, ...channel };
}

async function scheduleNotification(content, trigger) {
  if (!trigger) return;
  await Notifications.scheduleNotificationAsync({ content, trigger });
}

export async function registerForRemoteNotifications() {
  const granted = await notificationPermissionGranted();
  await configureAndroidChannel();
  if (!granted || !Device.isDevice) return null;

  const projectId = process.env.EXPO_PUBLIC_EAS_PROJECT_ID || Constants.expoConfig?.extra?.eas?.projectId || Constants.easConfig?.projectId;
  if (!projectId) return null;

  const token = (await Notifications.getExpoPushTokenAsync({ projectId })).data;
  await SecureStore.setItemAsync(PUSH_TOKEN_KEY, token);
  return token;
}

export async function storedPushToken() {
  return SecureStore.getItemAsync(PUSH_TOKEN_KEY);
}

export async function clearStoredPushToken() {
  await SecureStore.deleteItemAsync(PUSH_TOKEN_KEY);
}

export async function cancelLocalCareNotifications() {
  await Notifications.cancelAllScheduledNotificationsAsync();
}

export async function scheduleLocalCareNotifications({ careProfileId, reminders, serviceRequests }) {
  const granted = await notificationPermissionGranted();
  await configureAndroidChannel();
  if (!granted) return;

  await cancelLocalCareNotifications();
  await Promise.all(reminders.filter((reminder) => reminder.status === "pending").map((reminder) => scheduleNotification(
    {
      title: "Goldenly reminder",
      body: `It’s time for ${reminder.title}.`,
      sound: "default",
      data: { type: "reminder", reminderId: reminder.id, careProfileId }
    },
    reminderTrigger(reminder)
  )));

  await Promise.all(serviceRequests.filter((request) => ["requested", "provider_assigned"].includes(request.status)).map((request) => {
    const notificationTime = request.preferred_time ? new Date(request.preferred_time).getTime() - (30 * 60 * 1000) : null;
    const triggerDate = notificationTime ? futureDate(notificationTime) : null;
    const channel = Platform.OS === "android" ? { channelId: ANDROID_CHANNEL_ID } : {};
    return scheduleNotification(
      {
        title: "Goldenly service reminder",
        body: `${request.service_name || request.service_type} is scheduled in 30 minutes.`,
        sound: "default",
        data: { type: "service_request", serviceRequestId: request.id, careProfileId }
      },
      triggerDate ? { type: Notifications.SchedulableTriggerInputTypes.DATE, date: triggerDate, ...channel } : null
    );
  }));
}
