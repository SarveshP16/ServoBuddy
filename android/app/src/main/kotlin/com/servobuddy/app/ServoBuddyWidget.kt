package com.servobuddy.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * The home screen widget: the next thing due and this month's spend. The app
 * works the text out and saves it (see home_widget_sync.dart); this only
 * draws it. Tapping opens the app on the car it's about.
 */
class ServoBuddyWidget : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    for (id in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.servobuddy_widget).apply {
        setTextViewText(R.id.widget_due_title, widgetData.getString("due_title", "Open ServoBuddy"))
        setTextViewText(R.id.widget_due_detail, widgetData.getString("due_detail", "to see what's due next"))
        setTextViewText(R.id.widget_month_label, widgetData.getString("month_label", "This month").orEmpty().uppercase())
        setTextViewText(R.id.widget_month_spend, widgetData.getString("month_spend", "—"))
        val link = Uri.parse(widgetData.getString("link", "servobuddy://home"))
        setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, link),
        )
      }
      appWidgetManager.updateAppWidget(id, views)
    }
  }
}
