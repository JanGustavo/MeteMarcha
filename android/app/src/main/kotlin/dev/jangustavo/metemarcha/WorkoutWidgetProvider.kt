package dev.jangustavo.metemarcha

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class WorkoutWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.workout_widget).apply {
                val title = widgetData.getString("workout_title", "Treino do Dia")
                val name = widgetData.getString("workout_name", "Nenhum agendado")
                val status = widgetData.getString("workout_status", "Mete Marcha!")

                setTextViewText(R.id.workout_title, title)
                setTextViewText(R.id.workout_name, name)
                setTextViewText(R.id.workout_status, status)

                // Define ícone dependendo se é descanso ou treino
                if (name?.contains("Descanso", ignoreCase = true) == true) {
                    setTextViewText(R.id.workout_icon, "😴")
                } else {
                    setTextViewText(R.id.workout_icon, "🏋️")
                }

                // Configura clique para abrir o app no split correto
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("metemarcha://workout")
                )
                setOnClickPendingIntent(R.id.workout_icon, pendingIntent)
                setOnClickPendingIntent(R.id.workout_name, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
