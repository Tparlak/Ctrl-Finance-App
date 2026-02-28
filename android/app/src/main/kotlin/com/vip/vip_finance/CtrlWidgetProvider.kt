package com.vip.vip_finance

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class CtrlWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val views = RemoteViews(context.packageName, R.layout.ctrl_widget_layout).apply {
            
            val balanceStr = widgetData.getString("balance", "₺0,00") ?: "₺0,00"
            val incomeStr = widgetData.getString("income", "Gelir: ₺0,00") ?: "Gelir: ₺0,00"
            val expenseStr = widgetData.getString("expense", "Gider: ₺0,00") ?: "Gider: ₺0,00"

            setTextViewText(R.id.widget_balance, balanceStr)
            setTextViewText(R.id.widget_income, incomeStr)
            setTextViewText(R.id.widget_expense, expenseStr)
        }
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
