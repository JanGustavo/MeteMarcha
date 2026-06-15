package dev.jangustavo.metemarcha

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class StreakWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.streak_widget).apply {
                val count = widgetData.getInt("streak_count", 0)
                setTextViewText(R.id.streak_count, count.toString())
                setTextViewText(R.id.streak_label, if (count == 1) "Semana" else "Semanas")

                // Configura clique para abrir o app
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("metemarcha://streak")
                )
                setOnClickPendingIntent(R.id.streak_icon, pendingIntent)
                // Também coloca no background
                setOnClickPendingIntent(R.id.streak_count, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
