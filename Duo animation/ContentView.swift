//
//  ContentView.swift
//  Duo animation
//
//  Exact iPhone Homescreen UI Reconstruction with Motion Tilt & Lift Blur
//

import SwiftUI
import CoreMotion
import Combine

// MARK: - Core Motion Manager
class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    @Published var rollVelocity: Double = 0.0
    
    private var lastRoll: Double = 0.0

    init() {
        startMotionUpdates()
    }

    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motionData, error in
            guard let self = self, let motion = motionData else { return }
            
            let newRoll = motion.attitude.roll * (180.0 / .pi)
            let newPitch = motion.attitude.pitch * (180.0 / .pi)
            
            self.rollVelocity = newRoll - self.lastRoll
            self.lastRoll = newRoll
            
            withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.75)) {
                self.roll = newRoll
                self.pitch = newPitch
            }
        }
    }

    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - Main ContentView
struct ContentView: View {
    @StateObject private var motion = MotionManager()
    
    // Simulator tilt fallback controls
    @State private var manualRoll: Double = 0.0
    @State private var manualPitch: Double = 0.0

    var effectiveRoll: Double {
        motion.roll != 0 ? motion.roll : manualRoll
    }
    
    var effectivePitch: Double {
        motion.pitch != 0 ? motion.pitch : manualPitch
    }

    // Progressive Leading-to-Trailing Column Wave Physics
    func columnLagWeight(forCol col: Int) -> Double {
        if effectiveRoll > 0 {
            // Tilting Right (lifting left side): Col 3 leads, Col 0 trails with max inertia
            return Double(3 - col) / 3.0
        } else if effectiveRoll < 0 {
            // Tilting Left (lifting right side): Col 0 leads, Col 3 trails with max inertia
            return Double(col) / 3.0
        }
        return 0.0
    }

    func colLagOffset(forCol col: Int) -> CGSize {
        let weight = columnLagWeight(forCol: col)
        let intensity = abs(effectiveRoll) / 10.0
        return CGSize(
            width: CGFloat(-effectiveRoll * weight * 0.55),
            height: 0 // Restricted vertical Y motion
        )
    }

    func colBlurRadius(forCol col: Int) -> CGFloat {
        let weight = columnLagWeight(forCol: col)
        let intensity = abs(effectiveRoll) / 10.0
        return CGFloat(weight * intensity * 10.0)
    }

    var dockBlurRadius: CGFloat {
        let intensity = abs(effectiveRoll) / 10.0
        return CGFloat(intensity * 12.0)
    }

    var dockLagOffset: CGSize {
        CGSize(
            width: CGFloat(-effectiveRoll * 0.35),
            height: 0
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let isSmallScreen = geometry.size.height < 850
            
            ZStack {
                // Background Wallpaper Image with Horizontal-Only Parallax Depth Shift
                Image(uiImage: UIImage(named: "wallpaper") ?? UIImage(named: "homescreen") ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(1.15)
                    .offset(
                        x: CGFloat(effectiveRoll * 1.2),
                        y: 0 // Restricted vertical Y parallax shift
                    )
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.15))

                let leadingMargin: CGFloat = isSmallScreen ? 20 : 24
                let trailingMargin: CGFloat = isSmallScreen ? 50 : 24
                let gridSpacing: CGFloat = isSmallScreen ? 14 : 16
                
                VStack(spacing: isSmallScreen ? 10 : 14) {
                    // Widgets Row (Weather & Calendar with Progressive Leading-to-Trailing Wave Blur)
                    HStack(spacing: gridSpacing) {
                        // Weather Widget (Columns 0-1)
                        VStack(spacing: 5) {
                            WeatherWidgetView()
                                .aspectRatio(1.0, contentMode: .fit)
                            Text("Weather")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                        .frame(maxWidth: .infinity)
                        .offset(colLagOffset(forCol: 0))
                        .blur(radius: colBlurRadius(forCol: 0) * 0.6)
                        .scaleEffect(1.0 + (colBlurRadius(forCol: 0) * 0.008))
                        
                        // Calendar Widget (Columns 2-3)
                        VStack(spacing: 5) {
                            CalendarWidgetView()
                                .aspectRatio(1.0, contentMode: .fit)
                            Text("Calendar")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                        .frame(maxWidth: .infinity)
                        .offset(colLagOffset(forCol: 3))
                        .blur(radius: colBlurRadius(forCol: 3) * 0.6)
                        .scaleEffect(1.0 + (colBlurRadius(forCol: 3) * 0.008))
                    }
                    .padding(.leading, leadingMargin)
                    .padding(.trailing, trailingMargin)
                    .padding(.top, isSmallScreen ? 10 : 16)

                    // 4x4 Main App Grid (Continuous Leading-to-Trailing Column Ripple Wave)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: 4), spacing: isSmallScreen ? 12 : 16) {
                        ForEach(0..<16, id: \.self) { index in
                            let col = index % 4
                            let app = gridApps[index]
                            
                            let offset = colLagOffset(forCol: col)
                            let blur = colBlurRadius(forCol: col)
                            
                            AppIconItemView(app: app, iconSize: isSmallScreen ? 54 : 60)
                                .offset(offset)
                                .blur(radius: blur)
                                .scaleEffect(1.0 + (blur * 0.012))
                        }
                    }
                    .padding(.leading, leadingMargin)
                    .padding(.trailing, trailingMargin)

                    Spacer(minLength: 0)

                    // Search Pill (With Dynamic Motion Blur & Lag Offset)
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11, weight: .bold))
                        Text("Search")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.vertical, 7)
                    .padding(.horizontal, 18)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                            .background(.ultraThinMaterial, in: Capsule())
                            .blur(radius: dockBlurRadius * 0.6)
                    )
                    .offset(dockLagOffset)
                    .blur(radius: dockBlurRadius * 0.45)

                    // Bottom Dock (Motion Blurred Glass Shelf Container + Icons)
                    HStack(spacing: 0) {
                        DockIconItem(iconType: .phone, badge: 18, size: isSmallScreen ? 54 : 60)
                            .offset(colLagOffset(forCol: 0))
                            .blur(radius: colBlurRadius(forCol: 0))
                            .frame(maxWidth: .infinity)
                        
                        DockIconItem(iconType: .safari, badge: 0, size: isSmallScreen ? 54 : 60)
                            .offset(colLagOffset(forCol: 1))
                            .blur(radius: colBlurRadius(forCol: 1))
                            .frame(maxWidth: .infinity)
                        
                        DockIconItem(iconType: .messages, badge: 32, size: isSmallScreen ? 54 : 60)
                            .offset(colLagOffset(forCol: 2))
                            .blur(radius: colBlurRadius(forCol: 2))
                            .frame(maxWidth: .infinity)
                        
                        DockIconItem(iconType: .music, badge: 0, size: isSmallScreen ? 54 : 60)
                            .offset(colLagOffset(forCol: 3))
                            .blur(radius: colBlurRadius(forCol: 3))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 34)
                            .fill(Color.white.opacity(0.25))
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 34))
                            .blur(radius: dockBlurRadius * 0.75)
                    )
                    .offset(dockLagOffset)
                    .blur(radius: dockBlurRadius * 0.45)
                    .padding(.leading, leadingMargin)
                    .padding(.trailing, trailingMargin)
                    .padding(.bottom, isSmallScreen ? 6 : 10)
                }
            }
            .rotation3DEffect(
                .degrees(effectiveRoll * 0.2),
                axis: (x: 0, y: 1, z: 0) // Strictly vertical Y axis rotation
            )
        }
    }
}


// MARK: - Weather & Calendar Widget Subviews
struct WeatherWidgetView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("New Delhi")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            
            Text("32°")
                .font(.system(size: 42, weight: .light))
                .foregroundColor(.white)
            
            Spacer(minLength: 0)
            
            HStack {
                Image(systemName: "cloud.fill")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.system(size: 14))
                Text("Mostly Cloudy")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            Text("H:32° L:27°")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.38, blue: 0.71), Color(red: 0.02, green: 0.25, blue: 0.52)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

struct CalendarWidgetView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("FRIDAY")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.red)
            
            Text("11")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(.white)
            
            Spacer(minLength: 0)
            
            Text("No Events Today")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.white.opacity(0.65))
                .padding(.bottom, 6)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

// MARK: - App Models & Icon Renderers
struct AppItem {
    let title: String
    let iconType: AppIconType
    let badge: Int
}

enum AppIconType {
    case facetime, calendar, photos, camera
    case mail, notes, reminders, clock
    case tv, games, appstore, maps
    case health, wallet, settings, sumdemo
    case phone, safari, messages, music
}

let gridApps: [AppItem] = [
    // Row 1
    AppItem(title: "FaceTime", iconType: .facetime, badge: 0),
    AppItem(title: "Calendar", iconType: .calendar, badge: 0),
    AppItem(title: "Photos", iconType: .photos, badge: 0),
    AppItem(title: "Camera", iconType: .camera, badge: 0),
    // Row 2
    AppItem(title: "Mail", iconType: .mail, badge: 0),
    AppItem(title: "Notes", iconType: .notes, badge: 0),
    AppItem(title: "Reminders", iconType: .reminders, badge: 0),
    AppItem(title: "Clock", iconType: .clock, badge: 0),
    // Row 3
    AppItem(title: "TV", iconType: .tv, badge: 0),
    AppItem(title: "Games", iconType: .games, badge: 0),
    AppItem(title: "App Store", iconType: .appstore, badge: 0),
    AppItem(title: "Maps", iconType: .maps, badge: 0),
    // Row 4
    AppItem(title: "Health", iconType: .health, badge: 0),
    AppItem(title: "Wallet", iconType: .wallet, badge: 0),
    AppItem(title: "Settings", iconType: .settings, badge: 2),
    AppItem(title: "SumDemo", iconType: .sumdemo, badge: 0)
]

struct AppIconItemView: View {
    let app: AppItem
    var iconSize: CGFloat = 60
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .topTrailing) {
                IconShapeView(iconType: app.iconType, size: iconSize)
                
                if app.badge > 0 {
                    Text("\(app.badge)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Circle().fill(Color.red))
                        .offset(x: 4, y: -4)
                }
            }
            Text(app.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                .lineLimit(1)
        }
    }
}

struct DockIconItem: View {
    let iconType: AppIconType
    let badge: Int
    var size: CGFloat = 60
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            IconShapeView(iconType: iconType, size: size)
            
            if badge > 0 {
                Text("\(badge)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Circle().fill(Color.red))
                    .offset(x: 6, y: -4)
            }
        }
    }
}

// Icon Graphics Renderer matching exact reference screenshot
struct IconShapeView: View {
    let iconType: AppIconType
    let size: CGFloat
    
    var body: some View {
        ZStack {
            switch iconType {
            case .facetime:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(LinearGradient(colors: [Color(red: 0.22, green: 0.85, blue: 0.42), Color(red: 0.12, green: 0.72, blue: 0.32)], startPoint: .top, endPoint: .bottom))
                Image(systemName: "video.fill")
                    .font(.system(size: size * 0.44))
                    .foregroundColor(.white)
                
            case .calendar:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(Color.white)
                VStack(spacing: 0) {
                    Text("Fri").font(.system(size: size * 0.18, weight: .bold)).foregroundColor(.red)
                    Text("11").font(.system(size: size * 0.44, weight: .semibold)).foregroundColor(.black)
                }
                
            case .photos:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(Color.white)
                // Rainbow Pinwheel
                ZStack {
                    Circle().fill(Color.red.opacity(0.85)).frame(width: size*0.2, height: size*0.2).offset(y: -size*0.08)
                    Circle().fill(Color.orange.opacity(0.85)).frame(width: size*0.2, height: size*0.2).offset(x: size*0.08)
                    Circle().fill(Color.green.opacity(0.85)).frame(width: size*0.2, height: size*0.2).offset(y: size*0.08)
                    Circle().fill(Color.blue.opacity(0.85)).frame(width: size*0.2, height: size*0.2).offset(x: -size*0.08)
                }
                
            case .camera:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(LinearGradient(colors: [Color(white: 0.9), Color(white: 0.7)], startPoint: .top, endPoint: .bottom))
                ZStack {
                    Circle().fill(Color.black).frame(width: size * 0.52, height: size * 0.52)
                    Circle().fill(Color.blue.opacity(0.85)).frame(width: size * 0.26, height: size * 0.26)
                    Circle().fill(Color.white.opacity(0.6)).frame(width: size * 0.08, height: size * 0.08).offset(x: -4, y: -4)
                }
                
            case .mail:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(LinearGradient(colors: [Color(red: 0.2, green: 0.6, blue: 1.0), Color(red: 0.0, green: 0.4, blue: 0.9)], startPoint: .top, endPoint: .bottom))
                Image(systemName: "envelope.fill")
                    .font(.system(size: size * 0.44))
                    .foregroundColor(.white)
                
            case .notes:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(Color.white)
                VStack(spacing: 0) {
                    Rectangle().fill(Color(red: 0.98, green: 0.82, blue: 0.2)).frame(height: size * 0.22)
                    Spacer()
                    VStack(spacing: 4) {
                        Divider()
                        Divider()
                        Divider()
                    }.padding(.horizontal, 6).padding(.bottom, 8)
                }
                .clipShape(RoundedRectangle(cornerRadius: size * 0.24))
                
            case .reminders:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(Color.white)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) { Circle().fill(Color.blue).frame(width: 6, height: 6); Rectangle().fill(Color.gray.opacity(0.4)).frame(height: 3) }
                    HStack(spacing: 6) { Circle().fill(Color.orange).frame(width: 6, height: 6); Rectangle().fill(Color.gray.opacity(0.4)).frame(height: 3) }
                    HStack(spacing: 6) { Circle().fill(Color.red).frame(width: 6, height: 6); Rectangle().fill(Color.gray.opacity(0.4)).frame(height: 3) }
                }.padding(8)
                
            case .clock:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(Color.white)
                ZStack {
                    Circle().stroke(Color.black.opacity(0.2), lineWidth: 1).padding(4)
                    Rectangle().fill(Color.black).frame(width: 2, height: size * 0.22).offset(y: -size * 0.11)
                    Rectangle().fill(Color.black).frame(width: 14, height: 2).offset(x: 7)
                    Rectangle().fill(Color.orange).frame(width: 1, height: size * 0.3).offset(y: -size * 0.1)
                }
                
            case .tv:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(Color.black)
                HStack(spacing: 2) {
                    Image(systemName: "applelogo").font(.system(size: size * 0.32))
                    Text("tv").font(.system(size: size * 0.32, weight: .bold))
                }.foregroundColor(.white)
                
            case .games:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.35, blue: 0.2), Color(red: 0.9, green: 0.1, blue: 0.2)], startPoint: .top, endPoint: .bottom))
                Image(systemName: "paperplane.fill")
                    .font(.system(size: size * 0.44))
                    .foregroundColor(.white)
                
            case .appstore:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(LinearGradient(colors: [Color(red: 0.15, green: 0.55, blue: 0.95), Color(red: 0.05, green: 0.4, blue: 0.85)], startPoint: .top, endPoint: .bottom))
                Image(systemName: "a.circle.fill")
                    .font(.system(size: size * 0.46))
                    .foregroundColor(.white)
                
            case .maps:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(LinearGradient(colors: [Color(red: 0.6, green: 0.9, blue: 0.5), Color(red: 0.3, green: 0.75, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: size * 0.44))
                    .foregroundColor(.blue)
                
            case .health:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(Color.white)
                Image(systemName: "heart.fill")
                    .font(.system(size: size * 0.44))
                    .foregroundColor(.pink)
                
            case .wallet:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(Color.black)
                VStack(spacing: -6) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.green).frame(width: size * 0.6, height: 10)
                    RoundedRectangle(cornerRadius: 4).fill(Color.orange).frame(width: size * 0.6, height: 10)
                    RoundedRectangle(cornerRadius: 4).fill(Color.blue).frame(width: size * 0.6, height: 10)
                }
                
            case .settings:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(LinearGradient(colors: [Color(white: 0.75), Color(white: 0.55)], startPoint: .top, endPoint: .bottom))
                Image(systemName: "gearshape.fill")
                    .font(.system(size: size * 0.46))
                    .foregroundColor(Color(white: 0.2))
                
            case .sumdemo:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(Color.white)
                Image(systemName: "square.grid.3x3.topleft.filled")
                    .font(.system(size: size * 0.42))
                    .foregroundColor(.gray)
                
            case .phone:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(LinearGradient(colors: [Color(red: 0.22, green: 0.85, blue: 0.42), Color(red: 0.12, green: 0.72, blue: 0.32)], startPoint: .top, endPoint: .bottom))
                Image(systemName: "phone.fill")
                    .font(.system(size: size * 0.44))
                    .foregroundColor(.white)
                
            case .safari:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(Color.white)
                Image(systemName: "safari.fill")
                    .font(.system(size: size * 0.46))
                    .foregroundColor(.blue)
                
            case .messages:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(LinearGradient(colors: [Color(red: 0.22, green: 0.85, blue: 0.42), Color(red: 0.12, green: 0.72, blue: 0.32)], startPoint: .top, endPoint: .bottom))
                Image(systemName: "message.fill")
                    .font(.system(size: size * 0.44))
                    .foregroundColor(.white)
                
            case .music:
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.22, blue: 0.37), Color(red: 0.85, green: 0.0, blue: 0.2)], startPoint: .top, endPoint: .bottom))
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.44))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
    }
}

#Preview {
    ContentView()
}


