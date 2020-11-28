import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as notifs;
import 'package:get_storage/get_storage.dart';
import 'package:rxdart/subjects.dart' as rxSub;
import 'package:waktusolatmalaysia/main.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:waktusolatmalaysia/views/GetPrayerTime.dart';

import '../CONSTANTS.dart';

final rxSub.BehaviorSubject<NotificationClass>
    didReceiveLocalNotificationSubject =
    rxSub.BehaviorSubject<NotificationClass>();
final rxSub.BehaviorSubject<String> selectNotificationSubject =
    rxSub.BehaviorSubject<String>();

class NotificationClass {
  final int id;
  final String title;
  final String body;
  final String payload;

  NotificationClass({this.id, this.body, this.payload, this.title});
}

Future<void> initNotifications(
    notifs.FlutterLocalNotificationsPlugin notifsPlugin) async {
  var initializationSettingsAndroid =
      notifs.AndroidInitializationSettings('icon');
  var initializationSettingsIOS = notifs.IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification:
          (int id, String title, String body, String payload) async {
        didReceiveLocalNotificationSubject.add(NotificationClass(
            id: id, title: title, body: body, payload: payload));
      });
  var initializationSettings = notifs.InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  await notifsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    if (payload != null) {
      print('notification payload: ' + payload);
    }
    selectNotificationSubject.add(payload);
  });
  print("Notifications initialised successfully");
}

void requestIOSPermissions(
    notifs.FlutterLocalNotificationsPlugin notifsPlugin) {
  notifsPlugin
      .resolvePlatformSpecificImplementation<
          notifs.IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}

Future<void> scheduleNotification(
    {notifs.FlutterLocalNotificationsPlugin notifsPlugin,
    int id,
    String title,
    String body,
    DateTime scheduledTime}) async {
  var androidSpecifics = notifs.AndroidNotificationDetails(
    id.toString(), // This specifies the ID of the Notification
    '$title notification', // This specifies the name of the notification channel
    'A scheduled prayer notification', //This specifies the description of the channel
    // icon: 'icon',
    color: Color(0xFF19e3cb),
  );
  var iOSSpecifics = notifs.IOSNotificationDetails();
  var platformChannelSpecifics =
      notifs.NotificationDetails(android: androidSpecifics, iOS: iOSSpecifics);
  await notifsPlugin.zonedSchedule(
      id, title, body, scheduledTime, platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: notifs
          .UILocalNotificationDateInterpretation
          .absoluteTime); // This literally schedules the notification
}

void schedulePrayNotification(List<dynamic> times) async {
  await notifsPlugin.cancelAll(); //reset all

  String currentLocation =
      locationDatabase.getDaerah(GetStorage().read(kStoredGlobalIndex));
  print(currentLocation);

  var currentTime = DateTime.now().millisecondsSinceEpoch;

  for (int i = 0; i < times.length; i++) {
    int subuhTimeEpoch = times[i][0] * 1000;
    int syurukTimeEpoch = times[i][1] * 1000;
    int zuhrTimeEpoch = times[i][2] * 1000;
    int asarTimeEpoch = times[i][3] * 1000;
    int maghribTimeEpoch = times[i][4] * 1000;
    int isyakTimeEpoch = times[i][5] * 1000;

    if (!(subuhTimeEpoch < currentTime)) {
      //to make sure the time is in future
      scheduleNotification(
        notifsPlugin: notifsPlugin,
        id: (subuhTimeEpoch / 1000).truncate(),
        title: 'It\'s Fajr',
        scheduledTime: tz.TZDateTime.from(
            DateTime.fromMillisecondsSinceEpoch(subuhTimeEpoch), tz.local),
        body: 'at ' + currentLocation,
      );
    }
    if (!(syurukTimeEpoch < currentTime)) {
      scheduleNotification(
          notifsPlugin: notifsPlugin,
          id: (syurukTimeEpoch / 1000).truncate(),
          title: 'It\'s Syuruk',
          body: 'at ' + currentLocation,
          scheduledTime: tz.TZDateTime.from(
              DateTime.fromMillisecondsSinceEpoch(syurukTimeEpoch), tz.local));
    }
    if (!(zuhrTimeEpoch < currentTime)) {
      scheduleNotification(
          notifsPlugin: notifsPlugin,
          id: (zuhrTimeEpoch / 1000).truncate(),
          title: 'It\'s Zuhr',
          body: 'at ' + currentLocation,
          scheduledTime: tz.TZDateTime.from(
              DateTime.fromMillisecondsSinceEpoch(zuhrTimeEpoch), tz.local));
    }
    if (!(asarTimeEpoch < currentTime)) {
      scheduleNotification(
          notifsPlugin: notifsPlugin,
          id: (asarTimeEpoch / 1000).truncate(),
          title: 'It\'s Asr',
          body: 'at ' + currentLocation,
          scheduledTime: tz.TZDateTime.from(
              DateTime.fromMillisecondsSinceEpoch(asarTimeEpoch), tz.local));
    }
    if (!(maghribTimeEpoch < currentTime)) {
      scheduleNotification(
          notifsPlugin: notifsPlugin,
          id: (maghribTimeEpoch / 1000).truncate(),
          title: 'It\'s Maghrib',
          body: 'at ' + currentLocation,
          scheduledTime: tz.TZDateTime.from(
              DateTime.fromMillisecondsSinceEpoch(maghribTimeEpoch), tz.local));
    }
    if (!(isyakTimeEpoch < currentTime)) {
      scheduleNotification(
          notifsPlugin: notifsPlugin,
          id: (isyakTimeEpoch / 1000).truncate(),
          title: 'It\'s Isya\'',
          body: 'at ' + currentLocation,
          scheduledTime: tz.TZDateTime.from(
              DateTime.fromMillisecondsSinceEpoch(isyakTimeEpoch), tz.local));
    }
    print('Subuh @ $subuhTimeEpoch');
    print('Syuruk @ $syurukTimeEpoch');
    print('Zohor @ $zuhrTimeEpoch');
    print('Asar @ $asarTimeEpoch');
    print('Maghrib @ $maghribTimeEpoch');
    print('Isyak @ $isyakTimeEpoch');
  }
}