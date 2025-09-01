package com.ikcoding.maikago

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    companion object {
        private const val CAMERA_PERMISSION_REQUEST_CODE = 100
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // エッジツーエッジ表示を有効化（Android 15以降の互換性のため）
        try {
            // FlutterActivityでは直接enableEdgeToEdge()を呼び出せないため、WindowCompatを使用
            WindowCompat.setDecorFitsSystemWindows(window, false)
            println("エッジツーエッジ表示を設定しました")
        } catch (e: Exception) {
            println("エッジツーエッジ設定でエラーが発生しました: ${e.message}")
        }
        
        // システムバーの状態をログ出力
        try {
            val statusBarHeight = resources.getDimensionPixelSize(
                resources.getIdentifier("status_bar_height", "dimen", "android")
            )
            val navigationBarHeight = resources.getDimensionPixelSize(
                resources.getIdentifier("navigation_bar_height", "dimen", "android")
            )
            println("ステータスバーの高さ: ${statusBarHeight}px")
            println("ナビゲーションバーの高さ: ${navigationBarHeight}px")
        } catch (e: Exception) {
            println("システムバーの高さ取得でエラー: ${e.message}")
        }
        
        // カメラ権限の確認と要求
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) 
            != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CAMERA),
                CAMERA_PERMISSION_REQUEST_CODE
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        when (requestCode) {
            CAMERA_PERMISSION_REQUEST_CODE -> {
                if (grantResults.isNotEmpty() && 
                    grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    // カメラ権限が許可された
                    println("カメラ権限が許可されました")
                } else {
                    // カメラ権限が拒否された
                    println("カメラ権限が拒否されました")
                }
            }
        }
    }
} 