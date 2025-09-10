//package com.morello.myapplication.presentation.theme
//
//import android.os.Bundle
//import androidx.activity.ComponentActivity
//import androidx.activity.compose.setContent
//import androidx.compose.foundation.Image
//import androidx.compose.foundation.background
//import androidx.compose.foundation.clickable
//import androidx.compose.foundation.layout.*
//import androidx.compose.foundation.shape.RoundedCornerShape
//import androidx.compose.material.Text
//import androidx.compose.runtime.Composable
//import androidx.compose.ui.Alignment
//import androidx.compose.ui.Modifier
//import androidx.compose.ui.draw.clip
//import androidx.compose.ui.graphics.Color
//import androidx.compose.ui.layout.ContentScale
//import androidx.compose.ui.res.painterResource
//import androidx.compose.ui.text.font.FontWeight
//import androidx.compose.ui.text.style.TextAlign
//import androidx.compose.ui.unit.dp
//import androidx.compose.ui.unit.sp
//import androidx.navigation.NavController
//import androidx.wear.compose.navigation.SwipeDismissableNavHost
//import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
//import androidx.wear.compose.navigation.composable
//
//
//
//class MainActivity : ComponentActivity() {
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//        setContent {
//            val navController = rememberSwipeDismissableNavController()
//            SwipeDismissableNavHost(
//                navController = navController,
//                startDestination = "logo_screen"
//            ) {
//                composable("logo_screen") {
//                    LogoScreen(navController)
//                }
//                composable("alert_screen") {
//                    AlertScreen()
//                }
//            }
//        }
//    }
//}
//
//@Composable
//fun LogoScreen(navController: NavController) {
//    Box(
//        modifier = Modifier
//            .fillMaxSize()
//            .background(Color(0xFF004576))
//            .clickable {
//                // Navega para a tela de alerta quando clicado
//                navController.navigate("alert_screen")
//            },
//        contentAlignment = Alignment.Center
//    ) {
//        Column(
//            horizontalAlignment = Alignment.CenterHorizontally,
//            verticalArrangement = Arrangement.Center
//        )
