import Foundation
import CoreMotion

// C ABI keeps the Unity IL2CPP bridge independent of generated Swift/Objective-C headers.
private final class TiltReader {
    let manager = CMMotionManager()
    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical)
    }
}
private let tiltReader = TiltReader()

@_cdecl("SwingMotion_Available")
public func swingMotionAvailable() -> Int32 {
    return tiltReader.manager.isDeviceMotionAvailable ? 1 : 0
}
@_cdecl("SwingMotion_Start")
public func swingMotionStart() { tiltReader.start() }
@_cdecl("SwingMotion_Stop")
public func swingMotionStop() { tiltReader.manager.stopDeviceMotionUpdates() }
@_cdecl("SwingMotion_Ready")
public func swingMotionReady() -> Int32 {
    return tiltReader.manager.isDeviceMotionActive && tiltReader.manager.deviceMotion != nil ? 1 : 0
}
@_cdecl("SwingMotion_Pitch")
public func swingMotionPitch() -> Float {
    guard let motion = tiltReader.manager.deviceMotion else { return 0 }
    // Screen-normal gravity works in either landscape orientation. Camera aiming only consumes this pitch channel.
    let screenGravity = max(-1.0, min(1.0, motion.gravity.z))
    return Float(-asin(screenGravity) * 180.0 / Double.pi)
}

// Independent screen-relative side tilt, used only by the gated Stage 2 bed.
@_cdecl("SwingMotion_Lateral")
public func swingMotionLateral(_ landscapeRight: Int32) -> Float {
    guard let motion = tiltReader.manager.deviceMotion else { return 0 }
    let sidewaysGravity = max(-1.0, min(1.0, motion.gravity.y))
    let orientationSign = landscapeRight == 1 ? 1.0 : -1.0
    return Float(asin(sidewaysGravity) * 180.0 / Double.pi * orientationSign)
}

// Camera-only angular velocity. Unlike asin(gravity.z), this continues through
// the face-down position and does not lose heading when looking at the floor.
@_cdecl("SwingMotion_CameraPitchRate")
public func swingMotionCameraPitchRate(_ landscapeRight: Int32) -> Float {
    guard let motion = tiltReader.manager.deviceMotion else { return 0 }
    let sign = landscapeRight == 1 ? 1.0 : -1.0
    // Unity positive pitch looks down; invert the device rate so lifting looks up.
    return Float(-motion.rotationRate.y * sign * 180.0 / Double.pi)
}

@_cdecl("SwingMotion_CameraYawRate")
public func swingMotionCameraYawRate() -> Float {
    guard let motion = tiltReader.manager.deviceMotion else { return 0 }
    let r = motion.rotationRate
    let g = motion.gravity
    return Float((r.x * g.x + r.y * g.y + r.z * g.z) * 180.0 / Double.pi)
}
