import Foundation
import MediaPipeTasksVision

class PoseAnalyzer {
    
    /// Calculate angle between three points
    static func calculateAngle(
        firstLandmark: NormalizedLandmark,
        midLandmark: NormalizedLandmark,
        lastLandmark: NormalizedLandmark
    ) -> Double {
        // Convert landmarks to 2D points for angle calculation
        let firstPoint = Point2D(x: firstLandmark.x, y: firstLandmark.y)
        let midPoint = Point2D(x: midLandmark.x, y: midLandmark.y)
        let lastPoint = Point2D(x: lastLandmark.x, y: lastLandmark.y)
        
        // Calculate vectors
        let vector1 = Point2D(x: firstPoint.x - midPoint.x, y: firstPoint.y - midPoint.y)
        let vector2 = Point2D(x: lastPoint.x - midPoint.x, y: lastPoint.y - midPoint.y)
        
        // Calculate dot product
        let dotProduct = vector1.x * vector2.x + vector1.y * vector2.y
        
        // Calculate magnitudes
        let magnitude1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
        let magnitude2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y)
        
        // Calculate angle in radians and convert to degrees
        let cosTheta = dotProduct / (magnitude1 * magnitude2)
        // Clamp cosTheta to avoid domain errors due to floating point precision
        let clampedCosTheta = max(-1.0, min(1.0, Double(cosTheta)))
        let angleRadians = acos(clampedCosTheta)
        let angleDegrees = angleRadians * 180.0 / .pi
        
        return angleDegrees
    }
    
    /// Analyze a squat from pose landmarks
    static func analyzeSquat(poseLandmarks: [NormalizedLandmark]) -> (kneeAngle: Double, hipAngle: Double, isSquatting: Bool) {
        guard poseLandmarks.count >= 33 else {
            return (0, 0, false)
        }
        
        // Define relevant landmarks for squat analysis
        // Using indexes from MediaPipe Pose model
        let leftHip = poseLandmarks[23]     // Left hip
        let leftKnee = poseLandmarks[25]    // Left knee
        let leftAnkle = poseLandmarks[27]   // Left ankle
        let leftShoulder = poseLandmarks[11] // Left shoulder
        
        // Calculate knee angle (ankle-knee-hip)
        let kneeAngle = calculateAngle(
            firstLandmark: leftAnkle,
            midLandmark: leftKnee,
            lastLandmark: leftHip
        )
        
        // Calculate hip angle (knee-hip-shoulder)
        let hipAngle = calculateAngle(
            firstLandmark: leftKnee,
            midLandmark: leftHip,
            lastLandmark: leftShoulder
        )
        
        // Determine if the person is squatting
        // A knee angle less than 110 degrees typically indicates a squat position
        let isSquatting = kneeAngle < 110
        
        return (kneeAngle, hipAngle, isSquatting)
    }
}

// Helper struct for 2D point calculations
struct Point2D {
    let x: Float
    let y: Float
} 