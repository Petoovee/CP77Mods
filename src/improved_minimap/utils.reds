module ImprovedMinimapUtil

import ImprovedMinimapMain.ZoomConfig

public class ZoomCalc {

  public static func GetForSpeed(speed: Int32) -> Int32 {
    if speed <= ZoomConfig.MinSpeed() { 
      return ZoomConfig.MinZoom(); 
    };
    if speed >= ZoomConfig.MaxSpeed() { 
      return ZoomConfig.MaxZoom(); 
    };

    // Calculate zoom increase step based on min/max values
    let speedRange: Float = Cast(ZoomConfig.MaxSpeed() - ZoomConfig.MinSpeed());
    let zoomRange: Float = Cast(ZoomConfig.MaxZoom() - ZoomConfig.MinZoom());
    let step: Float = zoomRange / speedRange;
    // Shift speed range for cases when MinSpeed is above zero
    let baseSpeed: Float = Cast(speed - ZoomConfig.MinSpeed());
    let zoomToAdd: Float = baseSpeed * step;
    let calculated: Float = Cast(ZoomConfig.MinZoom()) + zoomToAdd;
    // Round and return
    return RoundMath(calculated);
  }
}