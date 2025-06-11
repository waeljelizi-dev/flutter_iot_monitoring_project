

package com.example.emkamed_1;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.content.pm.PackageManager;
import android.Manifest;
import androidx.core.app.NotificationCompat;
import androidx.core.app.ActivityCompat;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import org.eclipse.paho.client.mqttv3.*;
import org.json.JSONObject;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String EVENT_CHANNEL = "com.example.dashboard/mqtt_event";
    private static final String METHOD_CHANNEL = "com.example.dashboard/mqtt_config";


    private EventChannel eventChannel;
    private EventChannel.EventSink eventSink;
    private MqttClient mqttClient;
    private static final String CHANNEL_ID = "mqtt_notifications_channel";
    private String brokerIp = "xxx.xxx.xxx.xxx";
    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);


        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), METHOD_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("setBrokerIp")) {
                        brokerIp = call.argument("ip");
                        result.success(true);
                    }else if (call.method.equals("unsubscribeAllTopics")) {
                        unsubscribeAllTopics();
                        result.success(true);
                    }else if (call.method.equals("disconnectMqtt")) {
                        disconnectMqttClient();
                        result.success(true);
                    } else {
                        result.notImplemented();
                    }
                });

        // Setup EventChannel
        eventChannel = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), EVENT_CHANNEL);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                eventSink = events;
                startMqttClient();
            }

            @Override
            public void onCancel(Object arguments) {
                eventSink = null;
                if (mqttClient != null && mqttClient.isConnected()) {
                    try {
                        mqttClient.disconnect();
                    } catch (MqttException e) {
                        e.printStackTrace();
                    }
                }
            }
        });
        createNotificationChannel();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 100);
            }
        }
    }


    private void unsubscribeAllTopics() {
        if (mqttClient != null && mqttClient.isConnected()) {
            try {
                mqttClient.unsubscribe("flu/test");
            } catch (MqttException e) {
                e.printStackTrace();
            }
        }
    }

    private void startMqttClient() {
        try {
            String clientId = MqttClient.generateClientId();
            mqttClient = new MqttClient("tcp://" + brokerIp + ":1883", clientId, null);
            MqttConnectOptions options = new MqttConnectOptions();
            options.setCleanSession(true);
            options.setConnectionTimeout(30);
            options.setKeepAliveInterval(60);

            new Thread(() -> {
                try {
                    mqttClient.connect(options);
                    mqttClient.subscribe("flu/test");
                    new Handler(Looper.getMainLooper()).post(() -> {
                        if (eventSink != null) {
                            eventSink.success("{\"status\":\"connected\",\"message\":\"MQTT connected successfully\"}");
                        }
                    });

                } catch (MqttException e) {
                    new Handler(Looper.getMainLooper()).post(() -> {
                        if (eventSink != null) {
                            String errorMessage = "Connection failed: ";
                            if (e.getReasonCode() == MqttException.REASON_CODE_BROKER_UNAVAILABLE) {
                                errorMessage += "Broker unavailable - Check IP address";
                            } else if (e.getReasonCode() == MqttException.REASON_CODE_CLIENT_TIMEOUT) {
                                errorMessage += "Connection timeout - Check network";
                            } else {
                                errorMessage += e.getMessage();
                            }
                            eventSink.error("MqttConnectionError", errorMessage, null);
                        }
                    });
                    e.printStackTrace();
                }
            }).start();

            mqttClient.setCallback(new MqttCallback() {
                @Override
                public void connectionLost(Throwable cause) {
                    if (eventSink != null) {
                        new Handler(Looper.getMainLooper()).post(() -> {
                            eventSink.error("MqttConnectionLost", "Lost connection to MQTT broker", null);
                        });
                    }

                    new Handler(Looper.getMainLooper()).postDelayed(() -> {
                        try {
                            if (!mqttClient.isConnected()) {
                                mqttClient.connect(options);
                                mqttClient.subscribe("flu/test");
                            }
                        } catch (MqttException e) {
                            e.printStackTrace();
                        }
                    }, 5000); 
                }

                @Override
                public void messageArrived(String topic, MqttMessage message) {
                    String receivedMessage = new String(message.getPayload());

                    try {
                        JSONObject json = new JSONObject(receivedMessage);
                        new Handler(Looper.getMainLooper()).post(() -> {
                            if (eventSink != null) {
                                eventSink.success(receivedMessage);
                            }
                        });

                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }

                @Override
                public void deliveryComplete(IMqttDeliveryToken token) {
                }
            });
        } catch (MqttException e) {
            // Handle client creation error
            if (eventSink != null) {
                new Handler(Looper.getMainLooper()).post(() -> {
                    eventSink.error("MqttClientError", "Failed to create MQTT client: " + e.getMessage(), null);
                });
            }
            e.printStackTrace();
        } catch (Exception e) {
            if (eventSink != null) {
                new Handler(Looper.getMainLooper()).post(() -> {
                    eventSink.error("UnexpectedError", "Unexpected error: " + e.getMessage(), null);
                });
            }
            e.printStackTrace();
        }
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            CharSequence name = "MQTT Notifications";
            String description = "Notifications for MQTT messages";
            int importance = NotificationManager.IMPORTANCE_HIGH;
            NotificationChannel channel = new NotificationChannel(CHANNEL_ID, name, importance);
            channel.setDescription(description);
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }

    private void disconnectMqttClient() {
        if (mqttClient != null && mqttClient.isConnected()) {
            try {
                mqttClient.disconnect();
            } catch (MqttException e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    protected void onDestroy() {
        if (mqttClient != null && mqttClient.isConnected()) {
            try {
                mqttClient.unsubscribe("flu/test");
                mqttClient.disconnect();
            } catch (MqttException e) {
                e.printStackTrace();
            }
        }
        super.onDestroy();
    }
}